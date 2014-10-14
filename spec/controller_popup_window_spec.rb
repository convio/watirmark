require_relative 'spec_helper'

describe 'Controller PopupWindow' do

  class PopupWindowView < Page
    popup_window_navigate_method Proc.new {
      Page.browser.element(:text, @name).click
    }
    keyword(:validate1) { browser.text_field(:id, 'validate1') }
    popup_window 'Open Dialog' do
      keyword(:firstname) { Page.browser.text_field(:name, 'firstname') }
      keyword(:lastname) { Page.browser.text_field(:name, 'lastname') }
    end
  end

  class PopupWindowController < Watirmark::WebPage::Controller
    @view = PopupWindowView
  end

  before :all do
    # @controller = PopupWindowController.new
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    Page.browser.goto "file://#{@html}"
  end

  it 'should be able to populate the popup window' do
    PopupWindowController.new(:validate1 => 'Awesome',
                              :firstname => 'Justin'
    ).populate_data
  end


end