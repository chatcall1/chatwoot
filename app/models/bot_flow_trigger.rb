class BotFlowTrigger < ApplicationRecord
  belongs_to :bot_flow
  belongs_to :account
  belongs_to :inbox

  validates :trigger_kind, inclusion: { in: %w[exact_match no_match] }
  validates :normalized_value, :value_hash, presence: true, if: :exact_match?
  validates :value_hash, uniqueness: { scope: [:account_id, :inbox_id] }, if: :exact_match?
  validates :inbox_id, uniqueness: { scope: :account_id }, if: :no_match?

  def self.normalize(value)
    value.to_s.unicode_normalize(:nfkc).strip.downcase
  end

  def self.fingerprint(value)
    Digest::SHA256.hexdigest(normalize(value))
  end

  private

  def exact_match? = trigger_kind == 'exact_match'
  def no_match? = trigger_kind == 'no_match'
end
