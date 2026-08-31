class Whatsapp::CampaignAudienceService
  pattr_initialize [:campaign!]

  def contacts
    @contacts ||= filtered_contacts.distinct
  end

  def conversations
    @conversations ||= begin
      scope = campaign.inbox.conversations.where(contact_id: contacts.select(:id))
      scope = scope.tagged_with(conversation_label_titles, any: true) if conversation_label_titles.present?
      scope = scope.joins(:messages)
                   .where(messages: { message_type: :incoming })
                   .where('messages.created_at > ?', Conversations::MessageWindowService::MESSAGING_WINDOW_24_HOURS.ago)

      Conversation.from(
        scope.select('DISTINCT ON (conversations.contact_id) conversations.*')
             .order('conversations.contact_id, conversations.last_activity_at DESC'),
        :conversations
      )
    end
  end

  def count
    custom_message? ? conversations.count : contacts.count
  end

  def custom_message?
    campaign.trigger_rules['message_type'] == 'custom'
  end

  private

  def filtered_contacts
    scope = campaign.inbox.contacts.where.not(phone_number: [nil, ''])
    scope = scope.tagged_with(target_label_titles, any: true) if targeting_by_labels? && target_label_titles.present?
    scope = scope.where.not(id: excluded_contacts.select(:id)) if excluded_label_titles.present?
    return scope if conversation_label_titles.blank?

    scope.where(id: matching_conversations.select(:contact_id))
  end

  def excluded_contacts
    campaign.account.contacts.tagged_with(excluded_label_titles, any: true)
  end

  def matching_conversations
    campaign.inbox.conversations.tagged_with(conversation_label_titles, any: true)
  end

  def targeting_by_labels?
    campaign.trigger_rules.fetch('audience_type', 'labels') == 'labels'
  end

  def target_label_titles
    label_titles(campaign.trigger_rules['target_label_ids'])
  end

  def excluded_label_titles
    @excluded_label_titles ||= label_titles(campaign.trigger_rules['excluded_label_ids'])
  end

  def conversation_label_titles
    @conversation_label_titles ||= label_titles(campaign.trigger_rules['conversation_label_ids'])
  end

  def label_titles(ids)
    campaign.account.labels.where(id: Array(ids)).pluck(:title)
  end
end
