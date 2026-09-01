class Whatsapp::CampaignPhoneAudienceService
  pattr_initialize [:account!, :inbox!, :phone_numbers!]

  def perform
    normalized_numbers = Array(phone_numbers).map { |number| normalize(number) }.uniq
    if normalized_numbers.empty? || normalized_numbers.any?(&:blank?)
      raise ArgumentError, 'Every phone number must be valid and use international format'
    end

    normalized_numbers.each { |phone_number| ensure_contact(phone_number) }
    normalized_numbers
  end

  private

  def normalize(number)
    value = number.to_s.tr('٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹', '01234567890123456789')
                  .gsub(/[\s\-()]/, '').sub(/\A00/, '+')
    return if !value.match?(/\A\+[1-9]\d{1,14}\z/) || !TelephoneNumber.parse(value).valid?

    value
  rescue StandardError
    nil
  end

  def ensure_contact(phone_number)
    contact = account.contacts.find_or_create_by!(phone_number: phone_number) { |record| record.name = phone_number }
    ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) { |record| record.source_id = phone_number.delete_prefix('+') }
  end
end
