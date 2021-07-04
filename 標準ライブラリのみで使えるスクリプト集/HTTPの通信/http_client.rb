# HTTP, HTTPSのGETやPOSTの送信処理を行うクラスです
# 通信処理を行うため標準ライブラリを読み込みます
require 'net/https'
# URL, URIを分解させるために標準ライブラリを読み込みます
require "uri"
# JSONでパラメータを送信することも多いため標準のjsonライブラリも読み込みます
require 'json'

class HttpClient
  # 指定したURLにGETのリクエストを送り、レスポンス情報を返します
  # @param [String] http(s)の通信を行いたいURL文字列情報。ex: https://example.com/foo/bar/
  # @return [Net::HTTPMovedPermanently]
  def get(url)
    uri    = build_uri(url)
    client = build_client(uri)

    client.get(uri.path)
  end

  # 指定したURLにPOSTでリクエストを送り、レスポンス情報を返します
  # @param [String] http(s)の通信を行いたいURL文字列情報。ex: https://example.com/foo/bar/
  # @param [String, Hash] POST時に一緒に送りたいパラメータ情報
  # @param [Boolean] パラメータがjsonかどうか。trueであればJSONとしてheaderを付与して送る
  # @return [Net::HTTPMovedPermanently]
  def post(url, params, json: false)
    uri         = build_uri(url)
    client      = build_client(uri)
    headers     = {}

    # json であれば header の Content-Type を追加する
    if json
      headers["Content-Type"] = "application/json"
    end

    # params の型を見てHash形式ならjsonに直す
    case params
    when Hash
      post_params = params.to_json
    else
      # それ以外なら文字列にする
      post_params = params.to_s
    end

    client.post(uri.path, post_params, headers)
  end

  private

  # Net::HTTPのクライアントを作成します
  # urlをもとにhttp, httpsのどちらの通信かを判断して、設定を分岐します
  # @param [URI] uri 通信を行いたい先のURIオブジェクト。詳しくは build_uri メソッドを参照ください。
  # @return [Net::HTTP]
  def build_client(uri)
    client = Net::HTTP.new(uri.host, uri.port)

    # もしhttpsならssl通信の設定を追加
    if uri.scheme == "https"
      client.use_ssl = true
      client.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    client
  end

  # 渡されたURL文字列情報からUIRオブジェクトを生成して返します。
  # @param [String] http(s)の通信を行いたいURL文字列情報。ex: https://example.com/foo/bar/
  # @return [URI]
  def build_uri(url)
    uri = URI.parse(url)

    # 送信時に uri.path が空文字だとArgumentErrorが発生するため、
    # 空文字のときは "/" を設定する
    if uri.path.empty?
      uri.path = "/"
    end

    uri
  end
end