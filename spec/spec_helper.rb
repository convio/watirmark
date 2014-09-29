lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.expand_path(lib_dir)

ENV['WEBDRIVER'] = 'firefox'


require 'rspec/autorun'
require 'watirmark'
require 'watirmark/configuration'

Watirmark.logger.level = Logger::FATAL

RSpec.configure do |config|
  config.mock_with :mocha
end

Watirmark.add_exit_task  { Watirmark::Session.instance.closebrowser }