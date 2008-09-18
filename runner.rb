
require 'rubygems'
require 'daemons'

require 'restful_routes'

Daemons.run(File.join(File.dirname(__FILE__), 'lib', 'restful_routes_control.rb'), {:backtrace => true, :log_output => true})
