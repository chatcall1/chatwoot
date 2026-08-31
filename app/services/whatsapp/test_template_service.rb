class Whatsapp::TestTemplateService
  pattr_initialize [:account!, :user!, :params!]

  def perform
    validate_inbox!
    process_contact_variables!
    name, namespace, language, parameters = processed_template
    raise ArgumentError, 'Template not found or its parameters are invalid' if name.blank?

    source_id = inbox.channel.send_template(phone_number, template_info(name, namespace, language, parameters), nil)
    raise ArgumentError, 'WhatsApp did not accept the test message' if source_id.blank?

    source_id
  end

  private

  def inbox
    @inbox ||= account.inboxes.find(params['inbox_id'])
  end

  def validate_inbox!
    raise ArgumentError, 'A WhatsApp inbox is required' unless inbox.inbox_type == 'Whatsapp'
  end

  def phone_number
    @phone_number ||= begin
      value = params['phone_number'].to_s.tr('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789').gsub(/[\s\-()]/, '')
      value = "+#{value.delete_prefix('00')}" if value.start_with?('00')
      valid_phone_number = value.match?(/\A\+[1-9]\d{1,14}\z/) && TelephoneNumber.parse(value).valid?
      raise ArgumentError, 'Phone number must be a valid international number' unless valid_phone_number

      value
    end
  end

  def template_params
    @template_params ||= params.fetch('template_params', {}).deep_dup
  end

  def process_contact_variables!
    contact = account.contacts.find_by(phone_number: phone_number)
    if contact.blank? && template_params.to_json.match?(/\{\{\s*contact\./)
      raise ArgumentError,
            'Contact variables require an existing contact with the test phone number'
    end

    campaign = account.campaigns.new(inbox: inbox, sender: user, title: 'Template test', message: 'Template test')
    test_contact = contact || account.contacts.new(phone_number: phone_number)
    processor = Whatsapp::LiquidTemplateProcessorService.new(campaign: campaign, contact: test_contact)
    @template_params = processor.process_template_params(template_params)
  end

  def processed_template
    Whatsapp::TemplateProcessorService.new(channel: inbox.channel, template_params: template_params).call
  end

  def template_info(name, namespace, language, parameters)
    { name: name, namespace: namespace, lang_code: language, parameters: parameters }
  end
end
