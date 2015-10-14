require_relative "hook_helper"

Around('@catch-post-failure') do |scenario, block|
  HookHelper.trap_post_errors(&block)
end

Before('~@catch-post-failure') do
  HookHelper.clear_post_errors
end

Before do |scenario|
  HookHelper.serialize_models
end

After do |scenario|
  unless scenario.passed?
    folder = scenario.location.to_s[/\/features\/([^\.]*)/, 1]
    feature = scenario.title.tr(' ', '_')
    (file, file_type) = HookHelper.take_screenshot(folder, feature)
    embed file, file_type
  end
  HookHelper.serialize_models
end
