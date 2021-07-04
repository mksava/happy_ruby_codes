# Gemを読み込みます
require "aws-sdk-ses"

# AWSのSESを利用して簡単にメール送信を行えるクラスです。
# 【注意】
#   1.SESの設定を適切にしていなければ、Fromのメールアドレスがなりすまし扱いとなります。設定についてはSESのマニュアルを確認してください。
#   2.SESは最初サンドボックスモードで認証できたメールアドレスの利用しかできません。試すときや開発環境ではSES側でメールアドレスの認証を行ってください。サンドボックスモードの解除方法はマニュアルをご確認ください。
class AwsSesOperate
  # メールのエンコーディング文字列。メソッド利用時に変更できますが指定をしないときのデフォルト値です。
  DEFAULT_ENCODING = "UTF-8"

  # SESの操作を行うにあたり必要な設定を行います。
  # 環境変数を設定していない限りは本メソッドを実行して明示的にregion等をまとめて設定してください
  # @param [String] region SESの操作を行う対象のリージョン情報
  # @param [String] access_key IAMで発行されたSESへ操作権限があるアクセスキーID
  # @param [String] secret_key IAMで発行されたSESへ操作権限があるシークレットキー
  # @note
  #   region一覧は下記から参照できます。東京は「ap-northeast-1」です。
  #   https://docs.aws.amazon.com/ja_jp/general/latest/gr/rande.html
  def set_config(region: nil, access_key: nil, secret_key: nil)
    @setting_region     = region
    @setting_access_key = access_key
    @setting_secret_key = secret_key
  end

  # SESを経由してメールを送信する
  # @param [String, Array] to メール送信先アドレス。宛先が1つならそのまま文字列でメールアドレスを指定してください。複数先に送るときは配列でメールアドレスを指定してください。
  # @param [String] from 相手側に表示されるメールの送信元アドレス
  # @param [String] subject メールの件名
  # @param [String] body メールの本文
  # @param [String] encoding メールの件名・本文の文字列エンコード。指定をしなければデフォルト値が使用されます。
  # @return [Seahorse::Client::Response] AwsのSDKが返すオブジェクトをそのまま返します
  def send(to, from, subject, body, encoding: DEFAULT_ENCODING)
    send_email(to, from, subject, body, encoding)
  end

  private

  # AWS SDK を利用してメールを送信します
  # Gemの使い方通りに使用をしていますので詳細はgem側の使い方を参照してください。
  # @param [String, Array] to メール送信先アドレス。宛先が1つならそのまま文字列でメールアドレスを指定してください。複数先に送るときは配列でメールアドレスを指定してください。
  # @param [String] from 相手側に表示されるメールの送信元アドレス
  # @param [String] subject メールの件名
  # @param [String] body メールの本文
  def send_email(to, from, subject, body, encoding)
    # 送信先のメールアドレスが1つか複数かを見て引数を設定する
    case to
    when Array
      # 配列であればそのまま指定
      to_addresses = to
    else
      # 1つであれば配列に変換する
      to_addresses = [to]
    end

    aws_client.send_email({
      destination: {
        to_addresses: to_addresses,
      },
      message: {
        body: {
          text: {
            charset: encoding,
            data: body,
          },
        },
        subject: {
          charset: encoding,
          data: subject,
        },
      },
      source: from,
    })
  end

  private

  # AWS SDK のメールクライアント
  # @see https://github.com/aws/aws-sdk-ruby/blob/master/gems/aws-sdk-ses/lib/aws-sdk-ses/client.rb
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

    @aws_client ||= Aws::SES::Client.new(
      region:            region,
      access_key_id:     access_key,
      secret_access_key: secret_key,
    )
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
end