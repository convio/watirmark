lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.expand_path(lib_dir)

ENV['WEBDRIVER'] = 'firefox'

require 'rspec/autorun'
require 'watirmark'

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
    if Watirmark::Configuration.instance.webdriver
      browser = Watir::Browser.new Watirmark::Configuration.instance.webdriver.to_sym
    else
      watir_options = Watir::IE.options
      browser = Watir::IE.new
      Watir::IE.set_options(watir_options)
    end
    at_exit{browser.close}
    browser
  end
end
