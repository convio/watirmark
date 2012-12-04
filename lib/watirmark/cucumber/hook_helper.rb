module HookHelper
  class << self

    def clear_post_errors
      Watirmark::Session.instance.post_failure = nil
    end

    def trap_post_errors(block)
      Watirmark::Session.instance.catch_post_failures(&block)
    end


    def take_screenshot
      image = "#{Time.now.to_i}-#{UUID.new.generate(:compact)}.png"
      path = "reports/screenshots"
      FileUtils.mkdir_p path unless File.directory? path
      Page.browser.screenshot.save "#{path}/#{image}"
      ["screenshots/#{image}", 'image/png']
    end

    def serialize_models
      Dir.mkdir("cache") unless Dir.exists? "cache"
      File.unlink "cache/DataModels" if File.exists? "cache/DataModels"
      File.open("cache/DataModels", "w") {|f| f.print Marshal::dump(DataModels)}
    end
  end
end
