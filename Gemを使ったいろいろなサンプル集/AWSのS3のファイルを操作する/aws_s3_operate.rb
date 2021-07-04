# Gemを読み込みます
require "aws-sdk-s3"

# AWSのS3に対してファイルの操作を行うクラスです。
# ファイルの読み込み、作成(アップロード)、削除を行えます。
class AwsS3Operate
  # S3の操作を行うにあたり必要な設定を行います。
  # 環境変数を設定していない限りは本メソッドを実行して明示的にregion等をまとめて設定してください
  # @param [String] region S3の操作を行う対象のリージョン情報
  # @param [String] access_key IAMで発行されたS3へ操作権限があるアクセスキーID
  # @param [String] secret_key IAMで発行されたS3へ操作権限があるシークレットキー
  # @note
  #   region一覧は下記から参照できます。東京は「ap-northeast-1」です。
  #   https://docs.aws.amazon.com/ja_jp/general/latest/gr/rande.html
  def set_config(region: nil, access_key: nil, secret_key: nil)
    @setting_region     = region
    @setting_access_key = access_key
    @setting_secret_key = secret_key
  end

  # S3にファイルをアップロードします。
  # もし指定したバケットがなければ作成を行い、ファイルをアップロードします
  # 同名のファイルがあるときは上書きされます。
  # ファイル名に / を混ぜるとディレクトリ構造にできます。
  # @param bucket_name [String] アップロードするS3のバケット名
  # @param file_name [String] アップロードするファイルの名前
  # @param file_body [String] アップロードするファイルの中身。もしファイルであればFile.readなどで中身を文字列で取得して設定してください。
  # @return [String] アップロードしたファイルを確認できるS3のコンソールパス
  def upload(bucket_name, file_name, file_body)
    # S3のバケット名に使えない文字列はここで置換およびチェックします。
    # _ は使えないので - に変換します。
    bucket = bucket_name.to_s.gsub("_", "-")
    # バケット名を正規表現でチェックします。
    if bucket.match(/\A^[0-9A-Za-z\-\.]+\Z/).nil?
      raise ArgumentError, "bucketの名前には半角英数字および-, .のみを使ってください"
    end

    # もしバケットが存在しなければ作成します。
    if bucket_not_exist?(bucket)
      aws_client.create_bucket(bucket: bucket)
    end

    # 指定バケットへファイルを作成します。
    aws_client.put_object(
      bucket: bucket,
      key:    file_name,
      body:   file_body
    )

    # 呼び出し元にはコンソールで確認できるURLを返す
    http_head = "https://s3.console.aws.amazon.com/s3/object/"
    region = get_region
    File.join(http_head, bucket, "#{file_name}?region=#{region}")
  end

  # S3のファイルを読み込みます。
  # @params bucket_name [String] 読み込みたいファイルのバケット名
  # @params file_name [String] 読み込みたいファイルの名前(Key)
  def read(bucket_name, file_name)
    object = aws_client.get_object(bucket: bucket_name, key: file_name)
    object.body.read
  end

  # S3のファイルを削除します。
  # オプション値を渡すと、バケットにファイルが無くなったときのみバケットも同時に削除します。
  # @param bucket_name [String] アップロードするS3のバケット名
  # @param file_name [String] 削除するS3に配置したファイル名
  # @param with_bucket [Bool] バケットを削除するか。trueのとき削除する。デフォルトfalse。ただしファイルがバケットに残っていれば消せません。
  # @return [String] 削除したファイル名
  def destroy(bucket_name, file_name, with_bucket: false)
    aws_client.delete_object(bucket: bucket_name, key: file_name)

    if with_bucket
      aws_client.delete_bucket(bucket: bucket_name)
    end
  end

  # 設定したregion情報などをもとにS3Clientオブジェクトを生成します。
  # 一度生成をしたオブジェクトはキャッシュを行い同インスタンスであれば使い回しを行います。
  # もし途中でregion情報等を書き換えたいときは再度インスタンスを生成してください。
  # @return [Aws::S3::Client] REGION等の情報を設定したAwsが用意したクライアント
  def aws_client
    # すでにオブジェクトを作っていればそのまま返す
    if already_client_initialized = !(@aws_client.nil?)
      return @aws_client
    end

    region = get_region
    access_key = get_access_key
    secret_key = get_secret_key
    # 最低限必要なパラメータが設定されていなければエラーを発生させる
    invalid_params = (region.to_s.empty? || access_key.to_s.empty? || secret_key.to_s.empty?)
    if invalid_params
      raise ArgumentError, "リージョン,アクセスキー、シークレットキーのいずれかが設定されていません。設定を確認してください。"
    end

    # 次回以降は同じクライアントを使い回せるようにキャッシュする
    @aws_client ||= begin
      Aws::S3::Client.new(
        region:            region,
        access_key_id:     access_key,
        secret_access_key: secret_key,
        endpoint:          get_end_point
      )
    end
  end

  private

  # バケットが存在するかを判定する
  # @return [Bool] 存在していればtrue
  def bucket_not_exist?(bucket_name)
    aws_client.list_buckets.buckets.all? do |bucket|
      bucket.name != bucket_name
    end
  end

  def get_region
    # 明示的に設定された値, 本クラスの命名規則の環境変数, AWSの命名規則の環境変数 の順番で値が設定されているものを返す
    @setting_region || ENV["S3_OPERATE_AWS_DEFAULT_REGION"] || ENV["AWS_DEFAULT_REGION"]
  end

  def get_access_key
    # 明示的に設定された値, 本クラスの命名規則の環境変数, AWSの命名規則の環境変数 の順番で値が設定されているものを返す
    @setting_access_key || ENV["S3_OPERATE_AWS_ACCESS_KEY_ID"] || ENV["AWS_ACCESS_KEY_ID"]
  end

  def get_secret_key
    # 明示的に設定された値, 本クラスの命名規則の環境変数, AWSの命名規則の環境変数 の順番で値が設定されているものを返す
    @setting_secret_key || ENV["S3_OPERATE_AWS_SECRET_ACCESS_KEY"] || ENV["AWS_SECRET_ACCESS_KEY"]
  end

  # S3のエンドポイント情報を返す
  # @return [String]
  def get_end_point
    "https://s3-#{get_region}.amazonaws.com"
  end  
end
