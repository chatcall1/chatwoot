class Whatsapp::CatalogTemplateProcessorService
  PRODUCT_BUTTON_TYPES = %w[CATALOG SPM MPM].freeze

  pattr_initialize [:channel!, :template!, :processed_params!]

  def call
    return [] unless catalog_template?
    return process_product_carousel if product_carousel?
    return process_single_product if commerce_button_type == 'SPM'
    return process_multi_product if commerce_button_type == 'MPM'

    process_catalog_button
  end

  def product_carousel?
    carousel_component&.dig('cards', 0, 'components')&.any? do |component|
      component['type'] == 'HEADER' && component['format'] == 'PRODUCT'
    end
  end

  private

  def process_catalog_button
    thumbnail_id = processed_params.dig('catalog', 'thumbnail_product_retailer_id').to_s.strip
    return [] if thumbnail_id.blank?

    [action_button('catalog', thumbnail_product_retailer_id: thumbnail_id)]
  end

  def process_single_product
    product_id = processed_params.dig('product', 'product_retailer_id').to_s.strip
    raise ArgumentError, 'Product retailer ID is required' if product_id.blank?

    [{ type: 'header', parameters: [product_parameter(product_id)] }]
  end

  def process_multi_product
    catalog = processed_params['catalog'] || {}
    thumbnail_id = catalog['thumbnail_product_retailer_id'].to_s.strip
    sections = build_sections(catalog['sections'])
    raise ArgumentError, 'A thumbnail product and at least one product section are required' if thumbnail_id.blank? || sections.empty?

    validate_section_limits!(sections)

    [action_button('mpm', thumbnail_product_retailer_id: thumbnail_id, sections: sections)]
  end

  def build_sections(raw_sections)
    Array(raw_sections).filter_map { |section| build_section(section) }
  end

  def build_section(section)
    title = section['title'].to_s.strip
    product_ids = Array(section['product_retailer_ids']).map(&:to_s).map(&:strip).reject(&:blank?)
    return if title.blank? || product_ids.empty?

    { title: title, product_items: product_ids.map { |id| { product_retailer_id: id } } }
  end

  def validate_section_limits!(sections)
    product_count = sections.sum { |section| section[:product_items].length }
    return if sections.length <= 10 && product_count <= 30

    raise ArgumentError, 'Multi-product templates support up to 10 sections and 30 products'
  end

  def process_product_carousel
    values = Array(processed_params.dig('carousel', 'cards'))
    raise ArgumentError, 'Product carousel requires between 2 and 10 products' unless values.length.between?(2, 10)

    cards = values.map.with_index { |value, index| product_carousel_card(value, index) }
    [{ type: 'carousel', cards: cards }]
  end

  def product_carousel_card(value, index)
    product_id = value['product_retailer_id'].to_s.strip
    raise ArgumentError, "Product retailer ID is required for card #{index + 1}" if product_id.blank?

    components = [{ type: 'header', parameters: [product_parameter(product_id)] }]
    components << dynamic_url_component(value, index) if dynamic_url_button?
    { card_index: index, components: components }
  end

  def dynamic_url_component(value, index)
    parameter = value['url_parameter'].to_s.strip
    raise ArgumentError, "URL parameter is required for card #{index + 1}" if parameter.blank?

    { type: 'button', sub_type: 'url', index: '0', parameters: [{ type: 'text', text: parameter }] }
  end

  def dynamic_url_button?
    card = carousel_component['cards'].first
    buttons = card['components'].find { |component| component['type'] == 'BUTTONS' }&.fetch('buttons', []) || []
    buttons.any? { |button| button['type'] == 'URL' && button['url'].to_s.include?('{{') }
  end

  def product_parameter(product_id)
    { type: 'product', product: { catalog_id: connected_catalog_id, product_retailer_id: product_id } }
  end

  def action_button(sub_type, action)
    { type: 'button', sub_type: sub_type, index: '0', parameters: [{ type: 'action', action: action }] }
  end

  def catalog_template?
    commerce_button_type.present? || product_carousel?
  end

  def commerce_button_type
    buttons = template['components']&.find { |component| component['type'] == 'BUTTONS' }&.fetch('buttons', []) || []
    buttons.find { |button| PRODUCT_BUTTON_TYPES.include?(button['type']) }&.dig('type')
  end

  def carousel_component
    @carousel_component ||= template['components']&.find { |component| component['type'] == 'CAROUSEL' }
  end

  def connected_catalog_id
    @connected_catalog_id ||= Rails.cache.fetch("whatsapp/catalog/#{channel.id}", expires_in: 15.minutes) do
      fetch_connected_catalog_id
    end
  end

  def fetch_connected_catalog_id
    response = Whatsapp::FacebookApiClient.new(channel.template_access_token).fetch_product_catalogs(
      channel.provider_config['business_account_id']
    )
    response.fetch('data').first&.fetch('id') || raise(ArgumentError, 'No Meta Commerce Catalog is connected')
  end
end
