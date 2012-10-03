require_relative 'spec_helper'

shared_examples_for "configuration_file" do
  it 'string' do
    @config.string.should == "foo"
  end

  it 'boolean' do
    @config.boolean.should be_true
  end

  it 'symbol' do
    @config.symbol.should == :foo
  end

  it 'integer' do
    @config.integer.should == 3
  end

  it 'float' do
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
