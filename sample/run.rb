# coding: utf-8


require_relative '../source/convert'

Encoding.default_external = "UTF-8"
$stdout.sync = true


option = {
  :mathjax_directory => "mathjax",
  :vis_directory => "vis",
  :jquery_path => "jquery/jquery.js",
  :comprehensive => true,
  :show_name => false,
  :show_popup_number => false
}
manager = ZeroFileManager.new(".", "out", option)
manager.convert