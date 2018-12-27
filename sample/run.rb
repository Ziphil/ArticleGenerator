# coding: utf-8


require_relative '../source/convert'

Encoding.default_external = "UTF-8"
$stdout.sync = true


option = {
  :mathjax_directory => "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5",
  :vis_directory => "https://cdnjs.cloudflare.com/ajax/libs/vis/4.21.0",
  :jquery_path => "https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js",
  :comprehensive => true,
  :show_name => false,
  :show_popup_number => false
}
manager = ZeroFileManager.new(".", "out", option)
manager.convert