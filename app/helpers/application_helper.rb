module ApplicationHelper
  def available_locales_with_name
    LANGUAGES_CONFIG.map do |_key, val|
      val.slice(:name, :iso_639_1_code).merge(direction: val.fetch(:direction, 'ltr'))
    end
  end

  def html_lang_attribute(locale)
    locale.to_s.tr('_', '-')
  end

  def language_direction(locale)
    language = LANGUAGES_CONFIG.values.find { |item| item[:iso_639_1_code] == locale.to_s }
    language&.fetch(:direction, 'ltr') || 'ltr'
  end

  def feature_help_urls
    features = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze
    features.each_with_object({}) do |feature, hash|
      hash[feature['name']] = feature['help_url'] if feature['help_url']
    end
  end
end
