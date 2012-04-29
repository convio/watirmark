if ENV['WEBDRIVER']
  require 'watir-webdriver'
  require 'watirmark/extensions/webdriver_extensions'
  require 'logger'
else
  require 'watir/ie'
  require 'watirmark/extensions/rautomation'
end
require 'watirmark/extensions/ruby_extensions'
require 'watirmark-log'
require 'watirmark/session'
require 'watirmark/exceptions'
require 'watirmark/configuration'
require 'watirmark/page/page'
require 'watirmark/controller/controller'
require 'american_date'