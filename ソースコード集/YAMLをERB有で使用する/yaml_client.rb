# YAMLを利用するため標準ライブラリのyamlをロードする
require "yaml"
# ERBを利用するため標準ライブラリのerbをロードする
require "erb"

class YamlClient
  # YAMLファイルをロードし、ERBで展開を行ったHashを返す
  # @param [String] yaml_file_path YAMLファイルへのパス
  # @param [String] namespace 常に先頭でアクセスする値があれば指定する。Railsでもよく使われる例です。詳細はexample.ymlを参照ください。
  # @return [Hash] YAMLをHashへ変換したオブジェクト
  def load(yaml_file_path, namespace: "")
    # Yamlファイルをロードする
    yaml_body = File.read(yaml_file_path)
    # ERBを実行する
    yaml_body = ERB.new(yaml_body).result

    # 結果をYAMLとしてロードする
    yaml = YAML.load(yaml_body)

    # もし名前空間が渡されていれば設定する
    if namespace.to_s.empty?
      yaml
    else
      yaml[namespace.to_s]
    end
  end
end