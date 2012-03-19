lib_dir = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.expand_path(lib_dir)

require 'rspec/autorun'

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
    watir_options = Watir::IE.options
    #Watir::IE.set_options(:visible => false)
    browser = Watir::IE.new
    Watir::IE.set_options(watir_options)
    at_exit{browser.close}
    browser
  end
end
