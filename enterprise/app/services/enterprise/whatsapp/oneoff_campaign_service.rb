module Enterprise::Whatsapp::OneoffCampaignService
  def perform
    validate_campaign!
    recipients = create_recipients
    process_recipients(recipients)
    campaign.completed!
  end

  private

  def process_recipient(recipient)
    return process_custom_recipient(recipient) if audience_service.custom_message?

    process_template_recipient(recipient)
  end

  def process_template_recipient(recipient)
    contact = recipient.contact
    Rails.logger.info "Processing contact: #{contact.name} (#{contact.phone_number})"

    if contact.phone_number.blank?
      Rails.logger.info "Skipping contact #{contact.name} - no phone number"
      recipient.mark_skipped!('Phone number is missing')
      return
    end

    if campaign.template_params.blank?
      Rails.logger.error "Skipping contact #{contact.name} - no template_params found for WhatsApp campaign"
      recipient.mark_skipped!('Template parameters are missing')
      return
    end

    processed_template_params = process_liquid_template_params(contact)
    if processed_template_params.nil?
      recipient.mark_skipped!('Template parameters could not be resolved')
      return
    end

    recipient.update!(message_content: rendered_message_content(contact))

    send_whatsapp_template_message(recipient: recipient, to: contact.phone_number, template_params: processed_template_params)
  end

  def create_recipients
    recipient_contacts.find_each.map do |contact|
      campaign.campaign_recipients.find_or_create_by!(contact: contact) do |recipient|
        recipient.account = campaign.account
        recipient.inbox = campaign.inbox
      end
    end
  end

  def recipient_contacts
    return audience_service.contacts unless audience_service.custom_message?

    campaign.account.contacts.where(id: audience_service.conversations.select(:contact_id))
  end

  def process_custom_recipient(recipient)
    conversation = conversations_by_contact_id[recipient.contact_id]
    return recipient.mark_skipped!('No eligible conversation inside the 24-hour messaging window') unless conversation

    message = Messages::MessageBuilder.new(campaign.sender, conversation, {
                                             content: campaign.message,
                                             message_type: 'outgoing',
                                             campaign_id: campaign.id
                                           }).perform
    recipient.update!(message_content: campaign.message)
    recipient.mark_sent!(message.source_id)
  rescue StandardError => e
    Rails.logger.error "Failed to send custom campaign #{campaign.id} to contact #{recipient.contact_id}: #{e.message}"
    recipient.mark_failed!(message: e.message)
  end

  def conversations_by_contact_id
    @conversations_by_contact_id ||= audience_service.conversations.index_by(&:contact_id)
  end

  def process_recipients(recipients)
    recipients.each { |recipient| process_recipient(recipient) }
  end

  def rendered_message_content(contact)
    Liquid::CampaignTemplateService.new(campaign: campaign, contact: contact).call(campaign.message)
  end

  def send_whatsapp_template_message(recipient:, to:, template_params:)
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    if name.blank?
      recipient.mark_skipped!('Template name could not be resolved')
      return
    end

    source_id = channel.send_template(to, template_info(name, namespace, lang_code, processed_parameters), nil)

    update_recipient_from_provider_response(recipient, source_id)
  rescue StandardError => e
    Rails.logger.error "Failed to send WhatsApp template message to #{to}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join('\n')}"
    recipient.mark_failed!(message: e.message)
    # continue processing remaining contacts
    nil
  end

  def template_info(name, namespace, lang_code, processed_parameters)
    {
      name: name,
      namespace: namespace,
      lang_code: lang_code,
      parameters: processed_parameters
    }
  end

  def update_recipient_from_provider_response(recipient, source_id)
    if source_id.present?
      recipient.mark_sent!(source_id)
    else
      recipient.mark_failed!(channel.last_provider_error || { message: 'WhatsApp provider did not return a message id' })
    end
  end
end
