require_relative 'spec_helper'

describe 'Controller PopupWindow' do

  class PopupWindowTestView < Page
    popup_window_navigate_method Proc.new {
      Page.browser.element(:text, @name).click
    }
    keyword(:validate1) { browser.text_field(:id, 'validate1') }
    popup_window 'Open Dialog' do
      keyword(:firstname) { Page.browser.text_field(:name, 'firstname') }
      keyword(:lastname) { Page.browser.text_field(:name, 'lastname') }
    end
    popup_window 'Open Dialog 2' do
      keyword(:firstname2) { Page.browser.text_field(:name, 'firstname2') }
      keyword(:lastname2) { Page.browser.text_field(:name, 'lastname2') }
    end
  end

  class PopupWindowTestController < Watirmark::WebPage::Controller
    @view = PopupWindowTestView
  end

  before :all do
    # @controller = PopupWindowController.new
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    Page.browser.goto "file://#{@html}"
  end

  it 'should be able to populate the popup window' do
    PopupWindowTestController.new(:validate1 => 'Awesome',
                              :firstname => 'Justin',
    ).populate_data
    expect(Page.browser.url).to match(/controller/)
  end

  it 'should be able to populate if there are mutliple popups open' do
    # pending 'This still does not work'
    # PopupWindowController.new(:validate1 => 'Awesome',
    #                           :firstname => 'Justin',
    #                           :firstname2 => 'John'
    # ).populate_data
  end

  it 'should be able to verify the popup window' do
    # pending 'This still does not switch to the main window'
    # PopupWindowController.new(:lastname => 'Chang').verify_data
    # expect(Page.browser.url).to match(/controller/)
    # Page.browser.windows.first.use
  end




end