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

module Setup
  @@browser = nil
  # Returns an invisible browser. Will reuse same browser if called multiple times.
  def self.browser
    @@browser ||= start_browser
  end
  private
  # Start invisible browser. Make sure browser is closed when tests complete.
  def self.start_browser
    browser = Watir::Browser.new Watirmark::Configuration.instance.webdriver.to_sym
    browser
  end
end

Watirmark.add_exit_task  { Page.browser.close }