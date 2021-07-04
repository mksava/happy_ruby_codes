# Gemを読み込みます
require "dynamoid"

=begin
  Dynamoid は初めに設定を行うことで、その後はRailsのActiveRecordのように扱うことができます。
  本ファイルではその初期設定部分と、よく使うであろう User クラスを作成します。

  【注意】
   1.AWSのDynamoDBはある程度無料で使えるのですが、初期設定の書き込み速度や読み込み速度では料金が発生します。DynamoDBのテーブルが作成されたら、設定の速度を落としておきましょう
     キャパシティをプロビジョンドに設定し、
     読み込みキャパシティーユニット, 書き込みキャパシティーユニット を 1 にすると節約できます。
   2.AWSのDynamoDBは1レコードあたり容量制限(400kb)があります。制限以上のデータを作成しようとするとエラーになりますのでご注意ください。
=end

# Dynamoid の設定を行うクラスです
# シンプルに内部にインスタンス変数を持ちたかったので、インスタンス化して使う作りにしています
class DynamoidSetting
  # DynamoDBの操作を行うにあたり必要な設定を行います。
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

  # Dynamoidの設定を行います。
  # このタイミングでtimezoneやネームスペースなどの細かな設定もできるようにしています
  # @param [String] timezone DynamoidおよびDynamoDBで扱う時刻のタイムゾーンを設定します。
  # @param [String] namespace DynamoDBのテーブルに共通でつける名前空間を設定できます。例えば neko と設定すると、ユーザテーブルが neko_user というようにプレフィックスがついて作成されます。
  # @param [Bool] date_as_string DynamoDBから取得される時間・日付を文字列として扱うかの設定です。trueにすると文字列、flaseにすると日付や時刻オブジェクトに変換して使えるようになります。
  # @note
  #   DynamoDBでは全部文字列が入るものとして扱っておいた方が設定が楽です。DynamoDBでは全てのフィールドに型を指定する必要があるのですが、全部文字列にしておけばテーブルのほうの型を意識しなくてすむからです。
  def setting(timezone: "Asia/Tokyo", namespace: "", date_as_string: true)
    region     = get_region
    access_key = get_access_key
    secret_key = get_secret_key
    # 最低限必要なパラメータが設定されていなければエラーを発生させる
    invalid_params = (region.to_s.empty? || access_key.to_s.empty? || secret_key.to_s.empty?)
    if invalid_params
      raise ArgumentError, "リージョン,アクセスキー、シークレットキーのいずれかが設定されていません。設定を確認してください。"
    end

    # Dynamoidの設定を行います。
    Dynamoid.configure do |config|
      # 認証系の設定です
      config.region = region
      config.access_key = access_key
      config.secret_key = secret_key

      # その他の細かな設定です
      config.namespace = namespace
      config.application_timezone = timezone
      config.dynamodb_timezone    = timezone
      # 時刻と日付を別々で文字列で扱うかを設定できますが今回はまとめています
      config.store_datetime_as_string = date_as_string
      config.store_date_as_string     = date_as_string
#      config.models_dir = File.join(__dir__, "remogu_record/models")
    end
  end

  private

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

# ユーザテーブルの例としてクラスを作成します
class User
  # 継承ではなくincludeでDynamoidの設定やメソッドを使えるようにします
  include Dynamoid::Document

  # 節約のため書き込み・読み込みのキャパシティーを最低の1にしておきます
  table read_capacity: 1, write_capacity: 1

  # テーブルで利用するfieldを明示的に記載する必要があります。型も本来指定が必要ですが指定しなければ文字列になります。
  # ひとまず名前とメールアドレスを管理するユーザテーブルを定義することとします
  field :name
  field :email

  # KVSの良さをいかすために以下のように serialized を指定したfiledを1つ作っておけば、
  # Hashとして値を保存したり取り出しすることもできます。
  field :options, :serialized

  # 保存時のバリデーションを設定することもできます。emailは必須にしています
  validates_presence_of :email
end