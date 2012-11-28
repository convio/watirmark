require_relative 'spec_helper'

shared_examples_for "configuration_file" do
  specify 'string' do
    @config.string.should == "foo"
  end

  specify 'true_boolean' do
    @config.true_boolean.should be_true
  end

  specify 'false_boolean' do
    @config.false_boolean.should be_false
  end

  specify 'symbol' do
    @config.symbol.should == :foo
  end

  specify 'integer' do
    @config.integer.should == 3
  end

  specify 'float' do
    @config.float.should == 1.2
  end
end

describe "text file" do
 it_behaves_like  "configuration_file"

  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.configfile = File.dirname(__FILE__) + '/configurations/config.txt'
    @config.read_from_file
  end
end

describe "yaml file" do
  it_behaves_like  "configuration_file"

  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.configfile = File.dirname(__FILE__) + '/configurations/config.yml'
    @config.read_from_file
  end
end

describe "configuration" do
  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.reload
  end

  specify 'add defaults' do
    @config.email.should == 'devnull'
    @config.webdriver.should == 'firefox'
    @config.defaults = {:email => 'email-changed'}
    @config.email.should == 'email-changed'
    @config.webdriver.should == 'firefox'
  end

  specify 'inspect' do
    @config.inspect.should =~ /^{.+}/
  end
  
  specify 'override how a setting is set' do
    module Watirmark
      class Configuration
        def hostname_value(hostname)
          hostname + '/test'
        end
      end
    end
    Watirmark::Configuration.instance.hostname = 'www.convio.com'
    Watirmark::Configuration.instance.hostname.should == 'www.convio.com/test'
  end

end
