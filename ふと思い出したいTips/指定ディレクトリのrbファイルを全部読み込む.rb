# このファイルを起点とした相対パスをディレクトリ名部分に入れる
Dir[File.join(__dir__, 'ディレクトリ名/**/*.rb')].each {|file| require file }