require_relative 'spec_helper'

describe 'Watirmark Statistics' do
  class StatisticsView < Page
    keyword(:validate1) { browser.text_field(:id, 'validate1') }
    keyword(:validate2) { browser.text_field(:id, 'validate2') }
    keyword(:validate3) { browser.text_field(:id, 'validate3') }
    keyword(:validate4) { browser.text_field(:id, 'validate4') }
    keyword(:text_fields) { browser.text_fields(:id, /^validate\d$/) }
    keyword(:checkbox) { browser.checkbox(:id, 'checkbox') }
    keyword(:dropdown) { browser.select(:name, 'select_list') }
    keyword(:submit_button) { browser.button(:id, 'button1') }
  end

  class StatisticsController < Watirmark::WebPage::Controller
    @view = StatisticsView

    def fill_forms
      @view.validate1.exists?
      @view.validate1.visible?
      @view.validate1.present?
      @view.validate1 = '1'
      @view.validate2 = '2'
      @view.validate3 = '3'
      @view.checkbox = true
      @view.dropdown.select_value('b')
      @view.submit_button.click
    end

    def multiple_elements
      @view.text_fields.each {|element| element.exists?}
    end

  end

  before :all do
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    @config = Watirmark::Configuration.instance
    @config.reload
    @config.statistics = true
    @session = Watirmark::Session.instance
    @b = @session.openbrowser
    @all_stats = @session.watirmark_statistics.start if @config.statistics
  end

  before :each do
    @each_stats = @session.watirmark_statistics.start if @config.statistics
    @b.goto "file://#{@html}"
    @statistics_controller = StatisticsController.new
  end

  after :each do
    @session.watirmark_statistics.stop(@each_stats)
  end

  after :all do
    File.open('watirmark_stats.txt', 'w') { |file| file.write("Totals\n#{@session.watirmark_statistics.stop(@all_stats).results}") }
    @config.statistics = false
  end

  specify 'Sleeps' do
    start_time = Time.now
    Watir::Wait.until { Time.now - start_time > 5 }
    expect(@each_stats.sleep_time).to be < 5
  end

  specify 'Navigations' do
    @b.refresh
    @b.goto "file://#{@html}"
    expect(@each_stats.navigations).to be == 3
    expect(@each_stats.navigation_time).to be > 0
  end

  specify 'Finding Elements' do
    @statistics_controller.fill_forms
    expect(@each_stats.found_elements.size).to be == 9
    expect(@each_stats.element_time).to be > 0
  end

  specify 'Finding Multiple Elements' do
    @statistics_controller.multiple_elements
    expect(@each_stats.found_elements.size).to be == 4
    expect(@each_stats.element_time).to be > 0
  end

  specify 'Clicking Elements' do
    @statistics_controller.fill_forms
    expect(@each_stats.clicks).to be == 4
    expect(@each_stats.click_time).to be > 0
  end

  specify 'Inputting Text' do
    @statistics_controller.fill_forms
    expect(@each_stats.text_input).to be == 3
    expect(@each_stats.text_input_time).to be > 0
  end

  specify 'Checking Errors' do
    test_checker = lambda do |page|
      page.text.include?("Server Error") and puts "Application exception or 500 error!"
    end
    @b.add_checker(test_checker)
    @statistics_controller.fill_forms
    @b.refresh
    @b.goto "file://#{@html}"
    expect(@each_stats.error_checks).to be == 4
    expect(@each_stats.error_time).to be > 0
    @b.disable_checker(test_checker)
  end

  specify 'Collects multiple sets of statistics simultaneously' do
    @statistics_controller.fill_forms

    @new_stats = @session.watirmark_statistics.start
    @statistics_controller.fill_forms

    @newer_stats = @session.watirmark_statistics.start
    @statistics_controller.fill_forms

    expect(@session.watirmark_statistics.stats_list.size).to be == 4
    expect(@newer_stats.found_elements.size).to be == 9
    expect(@new_stats.found_elements.size).to be == 18
    expect(@each_stats.found_elements.size).to be == 27
    @session.watirmark_statistics.stop(@newer_stats)
    @session.watirmark_statistics.stop(@new_stats)
    expect(@session.watirmark_statistics.stats_list.size).to be == 2
  end

end