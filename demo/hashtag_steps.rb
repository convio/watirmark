When /^I search for "(.*?)"$/ do |arg1|
  Search::Query.new(:search_term=>'#blackbaud').create
end

Then /^I should only see tweets containing the term "(.*?)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end
