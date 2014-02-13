#require_relative 'spec_helper'
#
#describe Watirmark::Session do
#  before :all do
#    @html   = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
#    @config = Watirmark::Configuration.instance
#    Watirmark::Session.instance.closebrowser
#  end
#
#  specify "check chrome to close the browser" do
#    @config.webdriver          = 'chrome'
#    @config.closebrowseronexit = true
#
#    @session = Watirmark::Session.instance
#    b        = @session.openbrowser
#    b.goto "file://#{@html}"
#    @session.closebrowser
#  end
#
#  specify "check firefox to close the browser" do
#    @config.webdriver          = 'firefox'
#    @config.closebrowseronexit = true
#
#    @session = Watirmark::Session.instance
#    b        = @session.openbrowser
#    b.goto "file://#{@html}"
#    @session.closebrowser
#  end
#
#end