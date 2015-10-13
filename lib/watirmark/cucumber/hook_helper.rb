module HookHelper
  class << self

    def clear_post_errors
      Watirmark::Session.instance.post_failure = nil
    end

    def trap_post_errors(&block)
      Watirmark::Session.instance.catch_post_failures(&block)
    end


    def take_screenshot(folder='', feature='')
      path = "reports/screenshots/#{folder}"
      if folder.empty?
        image = "#{Time.now.to_i}-#{UUID.new.generate(:compact)}.png"
      else
        image = "#{feature}.png"
      end
      file = "#{path}/#{image}"
      FileUtils.mkdir_p path unless File.directory? path
      begin
        if Page.browser.alert.exists?
          Watirmark.logger.warn("Alert is Open while taking screenshot: #{Page.browser.alert.text}")
          Page.browser.alert.close
        end
        Page.browser.screenshot.save file
        data = File.open(file, 'rb') { |f| f.read }
        data = Base64.encode64(data)
      rescue Exception => e
        Watirmark.logger.warn("Screenshot was not taken due to an exception")
        Watirmark.logger.warn(e.to_s)
        Watirmark.logger.warn(e.backtrace)
      end

      [data, 'image/png']
    end

    def serialize_models
      return unless Watirmark::Configuration.instance.use_cached_models
      Dir.mkdir("cache") unless Dir.exists? "cache"
      File.unlink "cache/DataModels" if File.exists? "cache/DataModels"
      File.open("cache/DataModels", "wb") { |f| f.print Marshal::dump(DataModels) }
    end
  end
end
