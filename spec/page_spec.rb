require 'spec_helper'
require 'watirmark'

describe 'Page' do

  before :all do
    Page.browser = nil
  end

  class Page1 < Page
    keyword(:a) {"a"}
    keyword(:b) {"b"}
  end
  class Page2 < Page
    keyword(:c) {"c"}
  end
  class Page3 < Page
    populate_keyword(:d) {"d"}
    verify_keyword(:e)   {"e"}
  end
  class Page4 < Page
    navigation_keyword(:f) {"f"}
    private_keyword(:g)    {"g"}
    keyword(:h)            {"h"}
  end
  class Page5 < Page1
    keyword(:i) {"i"}
  end

  it "should list its keywords" do
    Page1.keywords.should == [:a, :b]
    Page2.keywords.should == [:c]
  end

  it "should list its parent's keywords" do
    Page5.keywords.should == [:a, :b, :i]
  end


  it "should list populate and verify keywords" do
    Page3.keywords.should == [:d, :e]
  end

  it "should not list navigation or private keywords" do
    Page4.keywords.should == [:h]
  end

  it 'should permit verify and populate on keywords' do
    Page1.permissions[:a][:verify].should be_true
    Page1.permissions[:a][:populate].should be_true
    Page1.permissions[:b][:verify].should be_true
    Page1.permissions[:b][:populate].should be_true
    Page2.permissions[:c][:verify].should be_true
    Page2.permissions[:c][:populate].should be_true
    Page4.permissions[:h][:verify].should be_true
    Page4.permissions[:h][:populate].should be_true
  end

  it 'should permit verify on verify keywords' do
    Page3.permissions[:e][:verify].should be_true
  end

  it 'should permit populate on populate keywords' do
    Page3.permissions[:d][:populate].should be_true
  end

  it 'should not permit populate on verify keywords' do
    Page3.permissions[:e][:populate].should raise_error
  end

  it 'should not permit verify on populate keywords' do
    Page3.permissions[:d][:verfiy].should raise_error
  end

  it 'should permit nothing on private and navigation keywords' do
    Page4.permissions[:f].should raise_error
    Page4.permissions[:g].should raise_error
  end

  it 'should create a method for the keyword' do
    Page1.a.should == 'a'
    Page2.c.should == 'c'
    Page4.h.should == 'h'
  end

  it 'should be able to get and set the browser' do
    Page.browser = 'browser'
    Page1.browser.should == 'browser'
    Page2.browser.should == 'browser'
    Page3.browser.should == 'browser'
    Page4.browser.should == 'browser'
  end

  it 'should not leak keywords to other classes' do
    lambda{Page2.a}.should raise_error
    lambda{Page1.c}.should raise_error
  end

  it 'should support aliasing keywords' do
    class Page1 < Page
      keyword_alias :aliased_keyword, :a
    end
     Page1.a.should == 'a'
     Page1.methods.include?(:aliased_keyword).should be_true
     Page1.methods.include?(:aliased_keyword=).should be_true
     Page1.aliased_keyword.should == 'a'
  end

end

describe 'With window' do
  it 'should instance eval anything in the closure in the context of the window' do
    default_browser = mock('default-browser')
    default_browser.expects(:called).never
    Page.browser = default_browser
    other_browser = mock('other-browser')
    other_browser.expects(:called)
    Watirmark::with_window other_browser do
      Page.browser.called
    end
    Page.browser.should == default_browser
  end
end


