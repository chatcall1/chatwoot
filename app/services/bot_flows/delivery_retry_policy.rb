class BotFlows::DeliveryRetryPolicy
  TRANSIENT_PATTERNS = [
    /timeout/i,
    /temporar/i,
    /connection/i,
    /rate.?limit/i,
    /\b429\b/,
    /\b50[0234]\b/
  ].freeze

  def initialize(error)
    @error = error.to_s
  end

  def retryable?
    error.blank? || TRANSIENT_PATTERNS.any? { |pattern| pattern.match?(error) }
  end

  private

  attr_reader :error
end
