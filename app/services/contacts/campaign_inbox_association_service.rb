class Contacts::CampaignInboxAssociationService
  pattr_initialize [:data_import!, :contacts!]

  def perform
    inbox_id = data_import.source_metadata['campaign_inbox_id']
    return if inbox_id.blank?

    inbox = data_import.account.inboxes.find(inbox_id)
    contacts.each do |contact|
      contact = persisted_contact(contact)
      next if contact.phone_number.blank?

      source_id = contact.phone_number.delete_prefix('+')
      ContactInbox.find_or_create_by!(inbox: inbox, contact: contact) { |contact_inbox| contact_inbox.source_id = source_id }
    end
  end

  private

  def persisted_contact(contact)
    return contact if contact.id.present?
    return data_import.account.contacts.find_by!(identifier: contact.identifier) if contact.identifier.present?
    return data_import.account.contacts.from_email(contact.email) if contact.email.present?

    data_import.account.contacts.find_by!(phone_number: contact.phone_number)
  end
end
