class BotFlows::ConditionEvaluator
  def initialize(node, context)
    @node = node
    @context = context
  end

  def call
    matched = operator.in?(%w[contains not_contains]) ? source.include?(expected) : source == expected
    operator.in?(%w[not_equals not_contains]) ? !matched : matched
  end

  def source
    normalize(context[source_key])
  end

  private

  attr_reader :node, :context

  def source_key
    node.dig('data', 'source') == 'last_choice' ? 'last_choice' : 'incoming_message'
  end

  def operator = node.dig('data', 'operator')

  def expected = normalize(node.dig('data', 'value'))

  def normalize(value) = value.to_s.unicode_normalize(:nfkc).strip.downcase
end
