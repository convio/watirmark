require_relative 'spec_helper'

describe 'ProcessPage' do
  
  it 'should implement a process page interface' do
    lambda{Watirmark::ProcessPage.new('pp')}.should_not raise_error
  end
  
  it 'should support an activate method' do
    p = Watirmark::ProcessPage.new('pp')
    lambda{p.activate}.should_not raise_error(NoMethodError)
  end
  
end

describe 'Process Page Views' do
  
  class ProcessPageTest < Watirmark::Page
    keyword(:a) {'a'}
    process_page('ProcessPage 1') do 
      keyword(:b) {'b'}
    end
    process_page('ProcessPage 2') do
      keyword(:c) {'c'}
      keyword(:d) {'d'}
    end
    keyword(:e) {'e'}
  end
 
  it 'should only activate process_page when in the closure' do
    ProcessPageTest.a.should == 'a'
    ProcessPageTest.b.should == 'b'
    ProcessPageTest.c.should == 'c'
    ProcessPageTest.d.should == 'd'
    ProcessPageTest.e.should == 'e'
    ProcessPageTest.keywords.should == [:a,:b,:c,:d,:e]
  end
  
  it 'should show all keywords for a given process page' do
    ProcessPageTest['ProcessPage 1'].keywords.should == [:b]
    ProcessPageTest['ProcessPage 2'].keywords.should == [:c, :d]
  end
  
  
  class NestedProcessPageTest < Watirmark::Page
    keyword(:a) {'a'}
    process_page('ProcessPage 1') do 
      keyword(:b) {'b'}
      process_page('ProcessPage 1.1') do 
        keyword(:b1) {'b1'}
        keyword(:b2) {'b2'}
        process_page('ProcessPage 1.1.1') do 
          keyword(:b3) {'b3'}
        end
      end
    end
    keyword(:c) {'c'}
  end   
  
  it 'should activate the nested process_page where appropriate' do
    NestedProcessPageTest.a.should == 'a'
    NestedProcessPageTest.b.should == 'b'
    NestedProcessPageTest.b1.should == 'b1'
    NestedProcessPageTest.b2.should == 'b2'
    NestedProcessPageTest.b3.should == 'b3'
    NestedProcessPageTest.c.should == 'c'
  end
  
  it 'should show all keywords for a given nested rocess page' do
    NestedProcessPageTest['ProcessPage 1'].keywords.should == [:b]
    NestedProcessPageTest['ProcessPage 1 > ProcessPage 1.1'].keywords.should == [:b1, :b2]
    NestedProcessPageTest['ProcessPage 1 > ProcessPage 1.1 > ProcessPage 1.1.1'].keywords.should == [:b3]
  end
  
  class DefaultView < Watirmark::Page
    keyword(:a) {'a'}
    keyword(:b) {'b'}
  end
  
  class ProcessPageView < Watirmark::Page
    process_page 'page 1' do
      keyword(:a) {'a'}
    end
    process_page 'page 2' do
      keyword(:b) {'b'}
    end
  end
  
  class ProcessPageAliasView < Watirmark::Page
    process_page 'page 1' do
      process_page_alias 'page a'
      process_page_alias 'page b'
      keyword(:a) {'a'}
    end
    process_page 'page 2' do
      keyword(:b) {'b'}
    end
  end
  
  class ProcessPageSubclassView < ProcessPageView
    process_page 'page 3' do
      keyword(:c) {'c'}
    end
  end

  it 'should support defining the process page navigate method' do
    custom_method_called = false
    Watirmark::ProcessPage.navigate_method_default = Proc.new { custom_method_called = true }
    ProcessPageTest.a.should == 'a'
    custom_method_called.should be_false
    ProcessPageTest.b.should == 'b'
    custom_method_called.should be_true
  end

  it 'should support defining the process page submit method' do
    process_page = ProcessPageAliasView['page 1']
    process_page.alias.should == ['page a', 'page b']
  end
  
  it 'should be able to report all process pages' do
    ProcessPageView.process_pages[0].name.should == 'ProcessPageView'
    ProcessPageView.process_pages[1].name.should == 'page 1'
    ProcessPageView.process_pages[2].name.should == 'page 2'
    ProcessPageView.process_pages.size.should == 3
  end
  
  it 'should include process page keywords in subclasses' do
    ProcessPageSubclassView.process_pages[0].name.should == 'ProcessPageView'
    ProcessPageSubclassView.process_pages[1].name.should == 'page 1'
    ProcessPageSubclassView.process_pages[2].name.should == 'page 2'
    ProcessPageSubclassView.process_pages[3].name.should == 'ProcessPageSubclassView'
    ProcessPageSubclassView.process_pages[4].name.should == 'page 3'
    ProcessPageSubclassView.process_pages.size.should == 5
    ProcessPageSubclassView.keywords.should == [:a, :b, :c]
  end
end




