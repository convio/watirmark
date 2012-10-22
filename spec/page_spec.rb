require_relative 'spec_helper'

describe 'Page' do

  before :all do
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

    @page1 = Page1.new
    @page2 = Page2.new
    @page3 = Page3.new
    @page4 = Page4.new
    @page5 = Page5.new
  end

  it "should list its keywords" do
    @page1.keywords.should == [:a, :b]
    @page2.keywords.should == [:c]
  end

  it "should list its parent's keywords" do
    @page5.keywords.should == [:a, :b, :i]
  end


  it "should list populate and verify keywords" do
    @page3.keywords.should == [:d, :e]
  end

  it 'should permit verify and populate on keywords' do
    @page1.permissions[:a][:verify].should be_true
    @page1.permissions[:a][:populate].should be_true
    @page1.permissions[:b][:verify].should be_true
    @page1.permissions[:b][:populate].should be_true
    @page2.permissions[:c][:verify].should be_true
    @page2.permissions[:c][:populate].should be_true
    @page4.permissions[:h][:verify].should be_true
    @page4.permissions[:h][:populate].should be_true
  end

  it 'should permit verify on verify keywords' do
    @page3.permissions[:e][:verify].should be_true
  end

  it 'should permit populate on populate keywords' do
    @page3.permissions[:d][:populate].should be_true
  end

  it 'should not permit populate on verify keywords' do
    @page3.permissions[:e][:populate].should raise_error
  end

  it 'should not permit verify on populate keywords' do
    @page3.permissions[:d][:verfiy].should raise_error
  end

  it 'should permit nothing on private and navigation keywords' do
    @page4.permissions[:f].should raise_error
    @page4.permissions[:g].should raise_error
  end

  it 'should create a method for the keyword' do
    @page1.a.should == 'a'
    @page2.c.should == 'c'
    @page4.h.should == 'h'
  end

  it 'should be able to get and set the browser' do
    old_browser = Page.browser
    begin
      Page.browser = 'browser'
      Page1.new.browser.should == 'browser'
      Page2.new.browser.should == 'browser'
      Page3.new.browser.should == 'browser'
      Page4.new.browser.should == 'browser'
    ensure
      Page.browser = old_browser
    end
  end

  it 'should not leak keywords to other classes' do
    lambda{@page2.a}.should raise_error
    lambda{@page1.c}.should raise_error
  end

  it 'should support aliasing keywords' do
    class Page1 < Page
      keyword_alias :aliased_keyword, :a
    end
    page1 = Page1.new
    page1.a.should == 'a'
    page1.aliased_keyword.should == 'a'
  end
end



