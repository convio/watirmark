require_relative 'spec_helper'

describe 'Page' do

  before :all do
    class Page1 < Page
      keyword(:a) { "a" }
      keyword(:b) { "b" }
    end
    class Page2 < Page
      keyword(:c) { "c" }
    end
    class Page3 < Page
      populate_keyword(:d) { "d" }
      verify_keyword(:e) { "e" }
    end
    class Page4 < Page
      navigation_keyword(:f) { "f" }
      private_keyword(:g) { "g" }
      keyword(:h) { "h" }
    end
    class Page5 < Page1
      keyword(:i) { "i" }
    end
    class Page6 < Page

    end

    @page1 = Page1.new
    @page2 = Page2.new
    @page3 = Page3.new
    @page4 = Page4.new
    @page5 = Page5.new
    @page6 = Page6.new
  end

  it "should handle empty keywords gracefully" do
    @page6.keywords.should == []
  end

  it "should list its keywords" do
    @page1.keywords.should == [:a, :b]
    @page2.keywords.should == [:c]
  end

  it "should list its parent's keywords" do
    @page5.keywords.should == [:a, :b, :i]
  end


  it "should list its own keywords" do
    @page5.native_keywords.should == [:i]
  end


  it "should list populate and verify keywords" do
    @page3.keywords.should == [:d, :e]
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
    lambda { @page2.a }.should raise_error
    lambda { @page1.c }.should raise_error
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

describe "keyword metadata inheritance" do

  before :all do
    class Parent < Page
      keyword(:a) { "a" }
      keyword(:b) { "b" }
      keyword(:same) { "c1" }
    end

    class Child < Parent
      keyword(:c) { "c" }
      keyword(:same) { "c1-child" }
    end

    class Child2 < Parent
      keyword(:g) { "g" }
    end
  end

  it 'should get declared keywords' do
    parent = Parent.new
    parent.keywords.should == [:a, :b, :same]
  end

  it 'should allow child to override superclass' do
    child = Child.new
    child.keywords.sort_by { |k| k.to_s }.should == [:a, :b, :c, :same]
    child.a.should == "a"
    child.same.should == 'c1-child'
  end

  it 'should not bleed settings between children' do
    child2 = Child2.new
    child2.keywords.sort_by { |k| k.to_s }.should == [:a, :b, :g, :same]
    child2.g.should == 'g'
    child2.same.should == 'c1'
  end
end




