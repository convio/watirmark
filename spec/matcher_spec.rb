require 'spec_helper'
require 'watirmark/webpage/matcher'

context Watirmark::Matcher do
  before :all do
    @matcher = Watirmark::Matcher.new
  end

  specify 'normalize dates' do
    @matcher.normalize_value("1/1/2012").should == Date.parse('1/1/2012')
    @matcher.normalize_value("1/1/09").should == Date.parse('1/1/09')
    @matcher.normalize_value("01/1/09").should == Date.parse('1/1/09')
    @matcher.normalize_value("01/01/09").should == Date.parse('1/1/09')
  end
  specify 'normalize whitespace' do
    @matcher.normalize_value(" a").should == "a"
    @matcher.normalize_value("a ").should == "a"
    @matcher.normalize_value("a\n").should == "a"
    @matcher.normalize_value("\na").should == "a"
    @matcher.normalize_value(" a \nb").should == "a \nb"
    @matcher.normalize_value(" a \r\nb").should == "a \nb"
    @matcher.normalize_value(" a \nb\n").should == "a \nb"
  end
  specify 'do not normalize string of spaces' do
    @matcher.normalize_value('     ').should == '     '
  end
end