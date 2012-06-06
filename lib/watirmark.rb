require 'watirmark/configuration'
Watirmark::Configuration.instance.reload

require 'watirmark/at_exit'
if Watirmark::Configuration.instance.webdriver
  require 'watir-webdriver'
  require 'watirmark/extensions/webdriver_extensions'
else
  require 'watir/ie'
  require 'watirmark/extensions/rautomation'
end
require 'watirmark/extensions/ruby_extensions'
require 'watirmark/session'
require 'watirmark/exceptions'
require 'watirmark/page/page'
require 'watirmark/controller/controller'
require 'american_date'
require 'watirmark/models'
require 'watirmark/rake/smoketest'
