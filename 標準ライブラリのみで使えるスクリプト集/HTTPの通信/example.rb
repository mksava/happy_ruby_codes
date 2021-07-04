require_relative "./http_client"

client = HttpClient.new

# Getの例
response = client.get("https://google.com")
puts response.code
puts response.body

# Postの例
response = client.post("https://google.com", "", json: false)
puts response.code
puts response.body

# SlackのIncoming Webhook の例
response = client.post(
  "https://hooks.slack.com/services/T01XXXXXXXX/XXXXXXXXXXX/XXXXXXXXXXYYYYYYYYYYZZZZ",
  { text: "チャットに投稿されるメッセージ" },
  json: true)
puts response.code
puts response.body
