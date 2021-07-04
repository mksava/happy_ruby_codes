require_relative "./yaml_client"

yaml_client = YamlClient.new

# 名前空間なし
yaml = yaml_client.load("./example.yml")
puts yaml["default"]["app_name"]
puts yaml["default"]["systems"]["erb_string"]
puts yaml["default"]["systems"]["animals"][0]
puts yaml["default"]["systems"]["stores"][0]["name"]

# 名前空間あり
yaml = yaml_client.load("./example.yml", namespace: "development")
puts yaml["app_name"]
puts yaml["systems"]["erb_string"]
puts yaml["systems"]["animals"][0]
puts yaml["systems"]["stores"][0]["name"]
