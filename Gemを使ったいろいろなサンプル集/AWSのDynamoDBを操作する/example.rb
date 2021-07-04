require_relative "./dynamoid_setting"

dynamoid_setting = DynamoidSetting.new
dynamoid_setting.set_config(
  region:     "東京であれば「ap-northeast-1」",
  access_key: "あなたのIAMユーザのAccessKeyId",
  secret_key: "あなたのIAMユーザのAccessSecretKey",
)

# 名前空間を指定してDynamoidの設定を行います。
# ここでは sample_user, というようにテーブルを作成できるようにします。
dynamoid_setting.setting(
  namespace: "sample",
)

# 保存処理の例です。
# インスタンスを生成します。
user = User.new(name: "mksava", email: "mksava@example.com")
# 保存します。このときテーブルがなければ自動的にテーブルも作られます。(時間がその分かかります)
user.save

# 読み込み処理の例です

# AvtiveRecordでは非推奨になった find_by_xxx が使えます。
user = User.find_by_name("mksava")
puts user.name
puts user.email

# Whereが使えます。
# ActiveRecordと同じく実体が必要になるまでDynamoDBにアクセスは走りません。
# そのため to_a や all などのメソッドを叩くことで値が取得されます
users = User.where(name: "mksava")
# ここで初めて値が取得される
users.each do |user|
  puts user.name
  puts user.email
end

# 更新処理の例です
user = User.find_by_name("mksava")
# nameを上書きして保存します。
user.name = "mksava2"
user.save

# 削除処理の例です
# ActiveRecordと同じように削除もできます。
User.where(name: "mksava2").delete_all