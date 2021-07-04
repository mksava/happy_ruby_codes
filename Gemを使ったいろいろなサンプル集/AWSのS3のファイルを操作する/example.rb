require_relative "./aws_s3_operate"

s3_operate = AwsS3Operate.new

# 設定
s3_operate.set_config(
  region:     "東京であれば「ap-northeast-1」",
  access_key: "あなたのIAMユーザのAccessKeyId",
  secret_key: "あなたのIAMユーザのAccessSecretKey",
)

# ファイルのアップロード
file = File.read("./example.txt")
upload_path = s3_operate.upload("対象バケット名", "samples/example.txt", file)
# アップロードしたファイルをAWSのコンソールで確認できるURL情報を表示
puts upload_path

# ファイルの読み込み
download_file = s3_operate.read("対象バケット名", "samples/example.txt")
# 読み込んだファイルの中身を表示
puts download_file

# ファイルの削除
s3_operate.destroy("対象バケット名", "samples/example.txt")
