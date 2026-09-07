# == Schema Information
#
# Table name: bot_flows
#
class BotFlow < ApplicationRecord
  SUPPORTED_CHANNEL_TYPES = %w[Channel::Whatsapp Channel::Instagram Channel::FacebookPage].freeze
  WHATSAPP_ONLY_NODE_TYPES = (%w[interactive interactive_button interactive_list] + BotFlows::MetaNodeValidator::TYPES).freeze

  belongs_to :account
  belongs_to :inbox
  has_many :bot_flow_executions, dependent: :destroy
  has_many :bot_flow_triggers, dependent: :delete_all
  has_many_attached :media_files, dependent: :destroy

  enum status: { draft: 0, published: 1, archived: 2 }

  validates :identifier, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true, length: { maximum: 80 }
  validates :trigger_kind, inclusion: { in: %w[exact_match no_match] }
  validate :inbox_belongs_to_account
  validate :supported_inbox
  validate :valid_draft_definition
  validate :nodes_supported_by_inbox
  validate :one_no_match_per_inbox

  before_validation :set_identifier, on: :create
  before_validation :sync_trigger_kind

  def publish!
    with_lock do
      publish_errors = BotFlows::PublishValidator.new(self).errors
      if publish_errors.any?
        publish_errors.each { |message| errors.add(:draft_definition, message) }
        raise ActiveRecord::RecordInvalid, self
      end

      update!(
        published_definition: draft_definition.deep_dup,
        published_at: Time.current,
        status: :published
      )
      BotFlows::TriggerIndexer.new(self).call
      BotFlows::MediaSynchronizer.new(self).call
    end
  end

  def unpublish!
    with_lock do
      update!(status: :archived)
      bot_flow_triggers.delete_all
    end
  end

  def synchronize_media_files! = BotFlows::MediaSynchronizer.new(self).call

  def required_media_signed_ids
    definitions = [draft_definition, published_definition].compact
    definitions.flat_map do |definition|
      definition.to_h.fetch('nodes', []).flat_map do |node|
        direct = [node.dig('data', 'blobSignedId').presence, node.dig('data', 'headerBlobSignedId').presence]
        card_files = Array(node.dig('data', 'cards')).filter_map { |card| card['blobSignedId'].presence }
        (direct + card_files).compact
      end
    end.uniq
  end

  private

  def set_identifier
    self.identifier ||= SecureRandom.uuid
  end

  def sync_trigger_kind
    trigger = draft_definition.to_h['nodes']&.find { |node| node['type'] == 'trigger' }
    self.trigger_kind = trigger&.dig('data', 'mode')
  end

  def inbox_belongs_to_account
    errors.add(:inbox, 'must belong to the same account') if inbox && inbox.account_id != account_id
  end

  def supported_inbox
    errors.add(:inbox, 'channel type is not supported') if inbox && SUPPORTED_CHANNEL_TYPES.exclude?(inbox.channel_type)
  end

  def valid_draft_definition
    validator = BotFlows::DraftValidator.new(draft_definition)
    validator.errors.each do |message|
      errors.add(:draft_definition, message)
    end
  end

  def one_no_match_per_inbox
    return unless trigger_kind == 'no_match' && account_id && inbox_id
    return unless self.class.where(account_id: account_id, inbox_id: inbox_id, trigger_kind: 'no_match').where.not(id: id).exists?

    errors.add(:trigger_kind, 'No Match already exists for this inbox')
  end

  def nodes_supported_by_inbox
    return if inbox&.channel_type == 'Channel::Whatsapp'

    has_whatsapp_nodes = draft_definition.to_h.fetch('nodes', []).any? do |node|
      WHATSAPP_ONLY_NODE_TYPES.include?(node['type'])
    end
    errors.add(:draft_definition, 'interactive nodes are only supported for WhatsApp inboxes') if has_whatsapp_nodes
  end
end

BotFlow.include_mod_with('BotFlow')
