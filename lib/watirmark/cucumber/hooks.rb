Around('@catch-post-failure') do |scenario, block|
  Watirmark::Session.instance.catch_post_failures(&block)
end

# Initialize post failures so we don't get leakage between scenarios
Before('~@catch-post-failure') do
  Watirmark::Session.instance.post_failure = nil
end