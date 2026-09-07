json.id bot_flow.id
json.reference "BOT-#{bot_flow.identifier.delete('-').first(8).upcase}"
json.name bot_flow.name
json.status bot_flow.status
platform = {
  'Channel::Whatsapp' => 'whatsapp',
  'Channel::Instagram' => 'instagram',
  'Channel::FacebookPage' => 'messenger'
}.fetch(bot_flow.inbox.channel_type)
json.platforms [platform]
json.inboxIds [bot_flow.inbox_id]
json.inbox do
  json.id bot_flow.inbox_id
  json.name bot_flow.inbox.name
  json.channelType bot_flow.inbox.channel_type
end
json.graph bot_flow.draft_definition
json.publishedAt bot_flow.published_at
json.createdAt bot_flow.created_at
json.updatedAt bot_flow.updated_at
json.lockVersion bot_flow.lock_version
