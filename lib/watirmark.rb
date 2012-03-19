if ENV['WEBDRIVER']
  require 'watir-webdriver'
  require 'logger'
else
  require 'watir/ie'
  require 'watirmark/extensions/ruby_extensions'
  require 'watirmark/extensions/rautomation'
end
require 'watirmark/session'
require 'watirmark/exceptions'
require 'watirmark-log'
require 'watirmark/configuration'
