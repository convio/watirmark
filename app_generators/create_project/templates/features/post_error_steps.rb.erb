# Exact matches
Then /^I should see the error: '?"?([^\/].*)"?'?$/ do |error|
  # Replace carriage returns with a space to make it easier to declare the error
  if Watirmark::IESession.instance.post_failure
    Watirmark::IESession.instance.post_failure.gsub(/[\r\n]+/, ' ').strip.should == error.strip
  else
    'No POST failure seen!'.should == error
  end
end

# Pattern matches
Then /^I should see the error: \/(.+)\/$/ do |error|
  # Replace carriage returns with a space to make it easier to declare the error
  error = model_gsub(error)
  Watirmark::IESession.instance.post_failure.gsub(/[\r\n]+/, ' ').should =~ /#{error}/
end

