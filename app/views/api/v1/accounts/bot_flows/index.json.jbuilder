json.array! @bot_flows do |bot_flow|
  json.partial! 'api/v1/accounts/bot_flows/bot_flow', bot_flow: bot_flow
end
