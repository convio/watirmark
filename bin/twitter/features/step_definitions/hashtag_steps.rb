# use generators

When /^I search for "(.*?)"$/ do |arg1|
  Search::Query.new(:search_term => arg1).create
end

Then /^I should only see tweets containing the term "(.*?)"$/ do |arg1|
  Search::Result.each { |result| result.should =~ /#{arg1}/i }
end
