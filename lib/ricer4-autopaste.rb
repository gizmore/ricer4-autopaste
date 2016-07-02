require "ricer4-irc"
require "ricer4-paste"
module Ricer4
  module Plugins
    module Paste
      
      add_ricer_plugin_module(File.dirname(__FILE__)+'/ricer4/autopaste')
      
    end
  end
end