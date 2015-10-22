require_relative 'spec_helper'

describe "Watirmark post checkers" do

  def post_checker_one
    @checker_ran = true
  end

  before :all do
    @checker_ran = false
    Watirmark::Session::POST_WAIT_CHECKERS << Proc.new { post_checker_one }
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    Page.browser.goto "file://#{@html}"
  end

  it 'open struct includes hash' do
    Page.browser.button(:id, 'button1').click
    @checker_ran.should == true
  end
end
