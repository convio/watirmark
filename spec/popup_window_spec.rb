require_relative 'spec_helper'

describe 'PopupWindow' do

  it 'should implement a popup window interface' do
    expect{ Watirmark::PopupWindow.new('ppw') }.to_not raise_error
  end

  it 'should support an activate method' do
    p = Watirmark::PopupWindow.new('ppw')
    expect{ p.activate }.to_not raise_error
  end

end

describe 'Popup Window Views' do

  before :all do
    class PopupWindowTest < Watirmark::Page
      keyword(:a) {'a'}
      popup_window('PopupWindow 1') do
        keyword(:b) {'b'}
      end
      popup_window('PopupWindow 2') do
        keyword(:c) {'c'}
        keyword(:d) {'d'}
      end
      keyword(:e) {'e'}
    end

    class PopupWindowView < Watirmark::Page
      popup_window 'window 1' do
        keyword(:a) {'a'}
      end
      popup_window 'window 2' do
        keyword(:b) {'b'}
      end
    end

    class PopupWindowAliasView < Watirmark::Page
      popup_window 'window 1' do
        popup_window_alias 'window a'
        popup_window_alias 'window b'
        keyword(:a) {'a'}
      end
      popup_window 'window 2' do
        keyword(:b) {'b'}
      end
    end

    class PopupWindowSubclassView < PopupWindowView
      popup_window 'window 3' do
        keyword(:c) {'c'}
      end
    end

    class PopupWindowCustomNav < Watirmark::Page
      popup_window_navigate_method Proc.new {}
      popup_window_submit_method Proc.new {}
      popup_window 'window 4' do
        keyword(:d) {'d'}
      end
    end

    @popupwindowtest = PopupWindowTest.new
    @popupwindow = PopupWindowView.new
    @popupwindowalias = PopupWindowAliasView.new
    @popupwindowsubclass = PopupWindowSubclassView.new
    @popupwindowcustomnav = PopupWindowCustomNav.new
  end

  it 'should only activate the popup_window when in the closure' do
    expect(@popupwindowtest.a).to eq('a')
    expect(@popupwindowtest.b).to eq('b')
    expect(@popupwindowtest.c).to eq('c')
    expect(@popupwindowtest.d).to eq('d')
    expect(@popupwindowtest.e).to eq('e')
    expect(@popupwindowtest.keywords).to eq([:a,:b,:c,:d,:e])
  end

  it 'should show all keywords for a given popup window' do
    expect(@popupwindowtest.popup_window('PopupWindow 1').keywords).to eq([:b])
    expect(@popupwindowtest.popup_window('PopupWindow 2').keywords).to eq([:c, :d])
  end

  it 'should support defining the popup window navigate method' do
    custom_method_called = false
    Watirmark::PopupWindow.navigate_method_default = Proc.new {custom_method_called = true}
    expect(@popupwindowtest.a).to eq('a')
    expect(custom_method_called).to be_falsey
    expect(@popupwindowtest.b).to eq('b')
    expect(custom_method_called).to be_truthy
  end

  it 'should support aliasing popup windows' do
    popup_window = @popupwindowalias.popup_window('window 1')
    expect(popup_window.alias).to eq(['window a', 'window b'])
    @popupwindowalias.popup_window('window a')
  end

  it 'should be able to report all popup windows' do
    expect(@popupwindow.popup_windows[0].name).to eq('window 1')
    expect(@popupwindow.popup_windows[1].name).to eq('window 2')
    expect(@popupwindow.popup_windows.size).to eq(2)
  end

  it 'should include popup_window keywords in subclasses' do
    @processpagesubclass.process_pages[0].name.should == ''
    @processpagesubclass.process_pages[1].name.should == 'page 1'
    @processpagesubclass.process_pages[2].name.should == 'page 2'
    @processpagesubclass.process_pages[3].name.should == ''
    @processpagesubclass.process_pages[4].name.should == 'page 3'
    @processpagesubclass.process_pages.size.should == 5
    @processpagesubclass.keywords.should == [:a, :b, :c]
  end


end