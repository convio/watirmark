require_relative 'spec_helper'

describe Watirmark::Session do
  before :all do
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    @config = Watirmark::Configuration.instance
  end

  before :each do
    Watirmark::Session.instance.closebrowser
    @config.reload
  end

  specify "check firefox to close the browser" do
    session = Watirmark::Session.instance
    b = session.openbrowser
    b.goto "file://#{@html}"
    session.closebrowser
    b.instance_variable_get('@closed').should be true
  end

  specify 'does not run headless when headless set to false' do
    @config.headless = false
    session = Watirmark::Session.instance
    b = session.openbrowser
    b.goto "file://#{@html}"
    b.title.should == "Controller Page"
    b.instance_variable_get('@closed').should be false
    session.instance_variable_get('@headless').should be_nil
  end

  # CI can not use chrome; must verify locally
  context "when running with Chrome" do
    xit "check chrome to close the browser" do
      @config.webdriver = 'chrome'
      session = Watirmark::Session.instance
      b = session.newsession
      b.goto "file://#{@html}"
      session.closebrowser
      b.instance_variable_get('@closed').should be true
    end

    # Have to use chrome; headless doesn't always play well with Firefox
    xit 'can run headless on linux' do
      @config.webdriver = 'chrome'
      @config.headless = true
      session = Watirmark::Session.instance
      b = session.openbrowser
      b.goto "file://#{@html}"
      b.title.should == "Controller Page"
      b.instance_variable_get('@closed').should be false
      session.instance_variable_get('@headless').should_not be_nil
    end
  end

end