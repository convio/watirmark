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

  it "should list its keywords" do
    Page1.keywords.should == [:a, :b]
    Page2.keywords.should == [:c]
  end
  
  it 'should create a method for the keyword' do
    Page1.a.should == 'a'
    Page2.c.should == 'c'
  end
  
  it 'should be able to get and set the browser' do
    Page.browser = 'browser'
    Page1.browser.should == 'browser'
    Page2.browser.should == 'browser'
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


