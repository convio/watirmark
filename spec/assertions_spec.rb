require 'spec_helper'
require 'watirmark/webpage/assertions'

describe Watirmark::Assertions do
  include Watirmark::Assertions
  
  it 'can compare simple elements' do
    element = stub(:exists? => true, :value => 'giant vampire squid', :radio_map => nil)
    assert_equal element, 'giant vampire squid'
  end
  
  it "can compare an isolated Watir element that doesn't 'exist'" do
    container = mock('container')
    container.expects(:page_container).returns(container)
    container.expects(:locate_input_element).returns(nil).at_least_once
    element = Watir::TextField.new(container, {:name => 'income'}, nil)
    assert_equal element, '!exist'
  end
  
  it "can compare an isolated Watir element that does 'exist'" do
    container = mock('container')
    container.expects(:page_container).returns(container)
    container.expects(:locate_input_element).returns('ole_element').at_least_once
    element = Watir::TextField.new(container, {:name => 'income'}, nil)
    element.expects(:value).returns('300')
    assert_equal element, '300'
  end
  
  it "can compare a RadioList with first choice selected" do
    container = mock('container')
    male_element = mock('male') # assumed to be first listed
    female_element = mock('female')
    container.expects(:page_container).returns(container)
    container.expects(:locate_input_element).with({:name => 'sex'}, nil, ['radio'], nil, Watir::Radio).returns(male_element).at_least_once
    container.expects(:locate_input_element).with({:name => 'sex'}, nil, ['radio'], 'M', Watir::Radio).returns(male_element).at_least_once
    male_element.expects(:checked).returns(true)
    male_element.expects(:invoke).returns ''
    male_element.expects(:getAttribute).with('name').returns 'sex'
    element = Watir::Radio.new(container, {:name => 'sex'}, nil, nil)
    assert_equal element, 'M'
    container.expects(:locate_input_element).with({:name => 'sex'}, nil, ['radio'], 'F', Watir::Radio).returns(female_element).at_least_once
    female_element.expects(:checked).returns(false)
    error = nil
    lambda{assert_equal element, 'F'}.should raise_error(Watirmark::VerificationException) {|e| error = e} # note: rspec bug: can't put "should" in this block
    error.expected.should == 'F'
    error.actual.should == '' # NOT CORRECT, but here to make sure we don't break it worse
  end
  
  it "can compare a RadioList with second choice selected" do
    container = mock('container')
    male_element = mock('male')
    female_element = mock('female') # assumed to be first listed
    container.expects(:page_container).returns(container)
    container.expects(:locate_input_element).with({:name => 'sex'}, nil, ['radio'], nil, Watir::Radio).returns(female_element).at_least_once
    container.expects(:locate_input_element).with({:name => 'sex'}, nil, ['radio'], 'M', Watir::Radio).returns(male_element).at_least_once
    male_element.expects(:checked).returns(true)
    element = Watir::Radio.new(container, {:name => 'sex'}, nil, nil)
    assert_equal element, 'M'
  end

  it 'compare integer' do
    element = stub(:exists? => true, :value => '100')
    assert_equal element, 100
  end

  it 'compare string integer' do
    element = stub(:exists? => true, :value => '100')
    assert_equal element, '100'
  end

  it 'expecting value with with percent' do
    element = stub(:exists? => true, :value => '100%')
    assert_equal element, '100%'
  end

  it 'expecting value with with a currency symbol' do
    element = stub(:exists? => true, :value => '$123.45')
    assert_equal element, '$123.45'
  end

  it 'expecting integer value should strip the dollar sign' do
    element = stub(:exists? => true, :value => '$25')
    assert_equal element, '25'
    assert_equal element, '$25'
    lambda { assert_equal element, '25%' }.should raise_error
  end

  it 'symbol in wrong place needs to match exactly or fail' do
    element = stub(:exists? => true, :value => '25$')
    lambda { assert_equal element, '$25' }.should raise_error
    assert_equal element, '25$'

    element = stub(:exists? => true, :value => '%50')
    lambda { assert_equal element, '50%' }.should raise_error
    lambda { assert_equal element, '50' }.should raise_error
    assert_equal element, '%50'
  end

  it 'should detect two different numbers are different' do
    element = stub(:exists? => true, :value => '50')
    lambda { assert_equal element, '51' }.should raise_error
    lambda { assert_equal element, '50.1' }.should raise_error
    lambda { assert_equal element, 49.9 }.should raise_error
    lambda { assert_equal element, 49 }.should raise_error
    assert_equal element, 50.0
  end

  it 'should let a number match a number with a $ before or % after' do
    element = stub(:exists? => true, :value => '$26', :name => 'unittest')
    assert_equal element, 26
    element = stub(:exists? => true, :value => '27%', :name => 'unittest')
    assert_equal element, 27.00
  end

  it 'should let a number in a string match a number with currency or percent' do
    element = stub(:exists? => true, :value => '$36', :name => 'unittest')
    assert_equal element, '36'
    element = stub(:exists? => true, :value => '37%', :name => 'unittest')
    assert_equal element, '37.00'
  end
  
end
