require_relative 'spec_helper'

describe Watirmark::WebPage::Controller do

  class TestView < Page
    keyword(:text_field)  {browser.text_field(:name, 'text_field')}
    keyword(:select_list) {browser.select_list(:name, 'select_list')}
  end

  class TestController < Watirmark::WebPage::Controller
    keyword :text_field
    attr_accessor :model
    @view = TestView
    def initialize
      super
      @model.text_field = 'foobar'
    end
  end

  class VerifyView < Page
    keyword(:validate1)   {browser.text_field(:id, 'validate1')}
    keyword(:validate2)   {browser.text_field(:id, 'validate2')}
    keyword(:validate3)   {browser.text_field(:id, 'validate3')}
    keyword(:validate4)   {browser.select_list(:id, 'validate3')}

    verify_keyword(:label1)      {browser.td(:id, 'label1')}
    verify_keyword(:value1)      {browser.td(:id, 'value1')}
    populate_keyword(:populate1) {browser.text_field(:id, 'validate4')}
    populate_keyword(:populate2) {browser.td(:id, 'value1')}

    private_keyword(:private_validate1)  {browser.text_field(:id, 'validate1')}
    navigation_keyword(:click_submit)    {browser.button(:id, 'Submit').click}
  end

  class VerifyController < Watirmark::WebPage::Controller
      @view = VerifyView
  end

  class TestControllerSubclass < TestController; end

  class Element
    attr_accessor :value
    def initialize(x)
      @value = x
    end
  end

  class ProcessPageControllerView < Page

    keyword(:a) {Element.new :a}
    process_page('Page 1') do
      keyword(:b) {Element.new :b}
    end
    process_page('Page 2') do
      keyword(:c) {Element.new :c}
      keyword(:d) {Element.new :d}
    end
    keyword(:e) {method :e}
    keyword(:radio_map,
      ['M'] => 'male',
      [/f/i] => 'female'
    )                {Page.browser.radio(:name, 'sex')}
  end

  class TestProcessPageController < Watirmark::WebPage::Controller
    attr_accessor :model
    @view = ProcessPageControllerView
  end

  before :all do
    @controller = TestController.new
    @keyword = @controller.class.specified_keywords[0]
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    Page.browser.goto "file://#{@html}"
  end

  it 'should supportradio maps in controllers' do
    lambda{
      @controller = TestProcessPageController.new(:radio_map => 'f').populate_data
    }.should_not raise_error
  end

  # We need to rethink radio maps. Currently this will only work properly if populate_data calls it.
  # If you override the populate_[radio_keyword] method then it stops working.
  it 'should supportradio maps in controllers in views' do
    pending 'this needs to be fixed'
    lambda{
      ProcessPageControllerView.radio_map.value = 'f'
    }.should_not raise_error
  end

  it 'should be able to create and use a new keyword' do
    @keyword.should == :text_field
    @controller.set @keyword, 'test'
    lambda{ @controller.check(@keyword, 'test')}.should_not raise_error(Watirmark::VerificationException)
  end

  it 'should be be able to interpret use value_for' do
    @controller.value_for(@keyword).should == 'foobar'
  end

  it 'should support override method to value_for' do
    class TestController
      def text_field_value
        'override'
      end
    end
    @controller.value_for(@keyword).should == 'override'
  end

  it 'should support override method for verification' do
    def @controller.verify_text_field; 'verify';  end
    @controller.expects(:verify_text_field).returns('verify').once
    @controller.verify_data
  end

  it 'should support keyword before and after methods' do
    def @controller.before_text_field; 'before'; end
    def @controller.after_text_field; 'after';  end
    @controller.expects(:before_text_field).returns('before').once
    @controller.expects(:after_text_field).returns('after').once
    @controller.populate {}
  end

  it 'should create class methods for the keyword in the controller' do
    TestController.respond_to?('keyword').should be_true
    TestController.respond_to?('keywords').should be_true
  end

  it 'should propogate page declaration to subclasses' do
    TestControllerSubclass.view.should == TestView
  end

  it 'works for simply happy path scenario' do
    @@element = mock()
    class MyView < Page
      keyword(:element) {@@element}
    end
    controller = Class.new Watirmark::WebPage::Controller do
      @view = MyView
      class << self
        attr_accessor :view
      end
    end
    controller.view.should == MyView
    @@element.expects(:exists?).at_least_once.returns(true)
    @@element.expects(:value).at_least_once.returns('new value')
    controller.verify :element => 'new value'
  end

  it 'should support direct reject requests' do
    class TestControllerReject < TestController
      reject :select_list
    end
    c = TestControllerReject.new
    c.respond_to?(:populate_select_list).should be_true
    c.respond_to?(:verify_select_list).should be_true
  end

  it 'should support direct populate_only requests' do
    class TestControllerPopulateOnly < TestController
      populate_only :select_list
    end
    c = TestControllerPopulateOnly.new
    c.respond_to?(:populate_select_list).should be_false
    c.respond_to?(:verify_select_list).should be_true
  end

  it 'should support direct verify_only requests' do
    class TestControllerVerifyOnly < TestController
      verify_only :select_list
    end
    c = TestControllerVerifyOnly.new
    c.respond_to?(:populate_select_list).should be_true
    c.respond_to?(:verify_select_list).should be_false
  end

  it 'should support before methods for process pages' do
    c = TestProcessPageController.new({:a=>1, :b=>1, :c=>1})
    def c.before_process_page_page_1; true; puts '11111'; end
    c.expects(:before_process_page_page_1).returns('true').once
    c.populate
  end

  it 'should throw a Watirmark::VerificationException when a verification fails' do
    lambda {
      VerifyController.new(:validate1 => '2').verify_data
    }.should raise_error(Watirmark::VerificationException,"validate1: expected '2.0' (Float) got '1' (String)")
  end

  it 'should not throw an exception when a verification succeeds' do
    VerifyController.new(:validate2 => 'a').verify_data
  end

  it 'should not throw an exception when many verifications succeed' do
    VerifyController.new(:validate1 => '1',:validate2 => 'a',:validate3 => 1.1).verify_data
  end

  it 'should only throw the first validation exception when there are 3 three problems' do
    lambda {
    VerifyController.new(:validate1 => 'z',:validate2 => 'y',:validate3 => 'x').verify_data
    }.should raise_error(Watirmark::VerificationException,/Multiple problems/)
  end

  it 'should throw an exception when verifying a verify_keyword fails' do
    lambda {
      VerifyController.new(:label1 => 'text').verify_data
    }.should raise_error(Watirmark::VerificationException,"label1: expected 'text' (String) got 'numbers' (String)")
  end

  it 'should not throw an exception when verifying a verify_keyword succeeds' do
    VerifyController.new(:label1 => 'numbers', :value1 => 1).verify_data
  end

  it 'should not throw an exception when populating with a verify_keyword' do
    VerifyController.new(:label1 => 'string').populate
  end

  it 'should throw an exception when populating a populate_keyword fails' do
    lambda {
      VerifyController.new(:populate2 => '32').populate
    }.should raise_error(NoMethodError)
  end

  it 'should not throw an exception when populating a populate_keyword succeeds' do
    VerifyController.new(:populate1 => '3.14159').populate
  end

  it 'should not throw an exception when verifying with a populate_keyword' do
    VerifyController.new(:populate1 => 'void').verify_data
  end

  it 'should not populate a private_keyword successfully' do
    c = VerifyController.new(:validate1 => 'hello')
    c.populate
    VerifyController.new(:private_validate1 => 'goodbye').populate
    c.verify_data
  end

  it 'should not verify a private_keyword successfully' do
    c = VerifyController.new(:private_validate1 => 'hello')
    VerifyController.new(:validate1 => 'goodbye').populate
    c.verify_data
  end

  it 'should not throw an exception when populating or verifying a private_keyword fails' do
    c = VerifyController.new(:private_validate1 => 'goodbye')
    c.populate
    c.model.update(:private_validate1 => 'hello')
    c.verify_data
  end

  it 'should not throw an exception when populating or verifying a navigation_keyword fails' do
    c = VerifyController.new(:button1 => 'Cancel')
    c.populate
    c.model.update(:button1 => 'Submit')
    c.verify_data
  end
end

describe "controllers should be able to detect and use embedded models" do
  before :all do
    class MyView < Page
      keyword(:element) {@@element}
    end
    @controller = Class.new Watirmark::WebPage::Controller do
      @view = MyView
    end
    Foo =  Watirmark::Model::Base.new(:first_name)
    User = Watirmark::Model::Base.new(:first_name)
    Login = Watirmark::Model::Base.new(:username)
    Password = Watirmark::Model::Base.new(:password)
    @password = Password.new
    @login = Login.new
    @login.add_model @password
    @model = User.new(:first_name=> 'first')
    @model.add_model @login
  end

  it 'should be able to see itself' do
    @model.find(User).should == @model
  end

  it 'should be able to see a sub_model' do
    @model.find(Login).should == @login
  end

  it 'should be able to see a nested sub_model' do
    @model.find(Password).should == @password
  end
end

describe "controllers should create a default model if one exists" do
  before :all do
    class MyView < Page
      private_keyword(:element)
    end
    MyModel = Watirmark::Model::Base.new(:element)
    @controller = Class.new Watirmark::WebPage::Controller do
      @view = MyView
      @model = MyModel
    end
  end

  it 'should be able to see itself' do
    c = @controller.new
    c.model.should be_kind_of(MyModel)
  end
end
