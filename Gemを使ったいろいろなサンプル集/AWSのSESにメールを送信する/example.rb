require_relative "./aws_ses_operate"

ses_operate = AwsSesOperate.new

# 設定
ses_operate.set_config(
  region:     "東京であれば「ap-northeast-1」",
  access_key: "あなたのIAMユーザのAccessKeyId",
  secret_key: "あなたのIAMユーザのAccessSecretKey",
)

# サンドボックスモードであれば to, from には認証済メールアドレスを設定してください。
# 認証していないメールアドレスを使っていれば、以下のようなエラーが発生します。
#  Email address is not verified. The following identities failed the check in region AP-NORTHEAST-1: xxxxx@example.com (Aws::SES::Errors::MessageRejected)

# メール送信(宛先が1つ)
response = ses_operate.send(
  "dosec.mk@gmail.com", # to
  "dosec.mk@gmail.com", # from
  "件名です！",
  "こんにちは。\n\nこのメールはSESを経由して送信されています。",
)
# 送信したメールを識別するためのIDを表示
puts response[:message_id]

# メール送信(宛先が2つ)
response = ses_operate.send(
  ["dosec.mk@gmail.com", "dosec.mk@example.com"], # to
  "dosec.mk@gmail.com", # from
  "件名2です！",
  "こんにちは。\n\nこのメールはSESを経由して送信されています。",
)
# 送信したメールを識別するためのIDを表示
puts response[:message_id]