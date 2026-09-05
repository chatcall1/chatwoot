module Whatsapp::ApiVersion
  def self.current
    GlobalConfigService.load('WHATSAPP_API_VERSION', nil).presence || raise('WHATSAPP_API_VERSION is not configured')
  end
end
