module Watirmark

  # This functionality allows us to ignore and buffer
  # post failures and then compare on a cucumber step
  module CucumberPostFailureBuffering
    @@buffer_post_failure = false
    @@post_failure = nil

    def post_failure
      @@post_failure
    end

    def post_failure=(x)
      @@post_failure = x
    end

    def buffer_post_failure
      @@buffer_post_failure
    end

    def catch_post_failures
      @@post_failure = nil
      @@buffer_post_failure = true
      yield
      @@buffer_post_failure = false
      @@post_failure
    end
  end

  class Session
    include Singleton
    include CucumberPostFailureBuffering

    POST_WAIT_CHECKERS = []

    def browser
      Page.browser
    end

    def browser=(x)
      Page.browser = x
    end

    def config
      Watirmark::Configuration.instance
    end

    # set up the global variables, reading from the config file
    def initialize
      Watirmark.add_exit_task {
        closebrowser if config.closebrowseronexit || config.headless
        @driver.quit if config.webdriver.to_s.eql? 'sauce'
      }

      if config.webdriver.to_s.eql? 'firefox'
        config.firefox_profile = default_firefox_profile
      elsif config.webdriver.to_s.eql? 'firefox_proxy'
        config.firefox_profile = proxy_firefox_profile(config.proxy_host, config.proxy_port)
      elsif config.webdriver.to_s.eql? 'chrome'
        config.chrome_profile = default_chrome_profile
      end
    end

    def default_chrome_profile
      download_directory = File.join(Configuration.instance.projectpath, "reports", "downloads")
      download_directory.gsub!("/", "\\") if Selenium::WebDriver::Platform.windows?

      {
          :download => {
              :prompt_for_download => false,
              :default_directory => download_directory
          }
      }
    end

    def default_firefox_profile
      file_types = "text/comma-separated-values,text/csv,application/pdf, application/x-msdos-program, application/x-unknown-application-octet-stream,
              application/vnd.ms-powerpoint, application/excel, application/vnd.ms-publisher, application/x-unknown-message-rfc822, application/vnd.ms-excel,
              application/msword, application/x-mspublisher, application/x-tar, application/zip, application/x-gzip, application/x-stuffit,
              application/vnd.ms-works, application/powerpoint, application/rtf, application/postscript, application/x-gtar,
              video/quicktime, video/x-msvideo, video/mpeg, audio/x-wav, audio/x-midi, audio/x-aiff, text/plain, application/vnd.ms-excel [official],
              application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/msexcel, application/x-msexcel,
              application/x-excel, application/vnd.ms-excel, application/excel, application/x-ms-excel, application/x-dos_ms_excel,
              text/csv, text/comma-separated-values, application/octet-stream, application/haansoftxls, application/msexcell,
              application/softgrid-xls, application/vnd.ms-excel, x-softmaker-pm"

      if Configuration.instance.default_firefox_profile
        Watirmark.logger.info "Using firefox profile: #{Configuration.instance.default_firefox_profile}"
        profile = Selenium::WebDriver::Firefox::Profile.from_name Configuration.instance.default_firefox_profile
      else
        profile = Selenium::WebDriver::Firefox::Profile.new
      end
      profile.native_events = false
      if Configuration.instance.projectpath
        download_directory = File.join(Configuration.instance.projectpath, "reports", "downloads")
        download_directory.gsub!("/", "\\") if Selenium::WebDriver::Platform.windows?
        profile['browser.download.folderList'] = 2 # custom location
        profile['browser.download.dir'] = download_directory
        profile['browser.helperApps.neverAsk.saveToDisk'] = file_types
        profile['security.warn_entering_secure'] =  false
        profile['security.warn_submit_insecure'] = false
        profile['security.warn_entering_secure.show_once'] = false
        profile['security.warn_entering_weak'] =  false
        profile['security.warn_entering_weak.show_once'] =  false
        profile['security.warn_leaving_secure'] =  false
        profile['security.warn_leaving_secure.show_once'] =  false
        profile['security.warn_viewing_mixed'] =  false
        profile['security.warn_viewing_mixed.show_once'] =  false
        profile['security.mixed_content.block_active_content'] = false
      end
      if config.firebug
        unless RbConfig::CONFIG['host_os'].match('linux')
          warn "Firebug with Firefox only supported on Linux"
          return
        end
        path = (File.expand_path "../../../bin/firefox_extensions/firebug", __FILE__)
        file = 'addon-1843-latest.xpi'
        Dir.chdir(path) do
          File.delete(file) if File.exists?(file)
          `wget https://addons.mozilla.org/firefox/downloads/latest/1843/addon-1843-latest.xpi`
        end
        profile.add_extension("#{path}/#{file}")
      end
      profile["focusmanager.testmode"] = true
      profile
    end

    def proxy_firefox_profile(hostname,port)
      profile = default_firefox_profile
      profile['network.proxy.http'] = hostname
      profile['network.proxy.http_port'] = port.to_i
      profile['network.proxy.ssl'] = hostname
      profile['network.proxy.ssl_port'] = port.to_i
      profile['network.proxy.ftp'] = hostname
      profile['network.proxy.ftp_port'] = port.to_i
      profile['network.proxy_type'] = 1
      profile['network.proxy.type'] = 1
      profile
    end

    def newsession
      closebrowser
      openbrowser
    end

    def openbrowser
      Watir.default_timeout = config.watir_timeout
      Watir.prefer_css = config.prefer_css
      Watir.always_locate = config.always_locate

      use_headless_display if config.headless
      Page.browser = new_watir_browser
      initialize_page_checkers
      Page.browser
    end

    def closebrowser
      begin
        Page.browser.close
      rescue Errno::ECONNREFUSED, Selenium::WebDriver::Error::WebDriverError
        # browser already closed or unavailable
      ensure
        Page.browser = nil
      end

      if @headless
        @headless.destroy
        @headless = nil
      end
    end

    def getos
      case RUBY_PLATFORM
        when /cygwin|mswin|mingw|bccwin|wince|emx/
          return "windows"
        when /darwin/
          return "mac"
        when /linux/
          return "linux"
      end
    end

    private

    def use_headless_display
      unless RbConfig::CONFIG['host_os'].match('linux')
        warn "Headless only supported on Linux"
        return
      end
      require 'headless'
      @headless = Headless.new
      @headless.start
    end

    def new_watir_browser
      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = config.http_timeout

      case config.webdriver.to_sym
      when :firefox, :firefox_proxy
        Watir::Browser.new :firefox, profile: config.firefox_profile, http_client: client
      when :sauce
        Watir::Browser.new use_sauce
      when :chrome
        Watir::Browser.new :chrome, prefs: config.chrome_profile, http_client: client
      else
        Watir::Browser.new config.webdriver.to_sym, http_client: client
      end
    end

    def use_sauce
      sb   = config.sauce_browser.nil? ? "firefox" : config.sauce_browser.to_s
      caps = sauce_config(sb)

      @driver = Selenium::WebDriver.for(
        :remote,
        :url                  => "http://#{config.sauce_username}:#{config.sauce_access_key}@ondemand.saucelabs.com:80/wd/hub",
        :desired_capabilities => caps)
      @driver
    end

    def sauce_config(sb)
      caps              = Selenium::WebDriver::Remote::Capabilities.send(sb.to_sym)
      caps.browser_name = sb
      case sb
        when "firefox"
          caps.version = config.sauce_browser_version.nil? ? 26 : config.sauce_browser_version.to_i
        when "chrome"
          caps.version = config.sauce_browser_version.nil? ? 32 : config.sauce_browser_version.to_i
        when "ie"
          caps.browser_name = "internet explorer" # caps.browser_name requires ie to be full name
          caps.version      = config.sauce_browser_version.nil? ? 10 : config.sauce_browser_version.to_i
      end
      caps.platform = config.sauce_os.nil? ? "Windows 7" : config.sauce_os.to_s
      caps[:name]   = config.sauce_test_title.nil? ? "Testing Selenium 2 with Ruby on Sauce" : config.sauce_test_title
      puts caps
      caps
    end

    def initialize_page_checkers
      POST_WAIT_CHECKERS.each { |p| Page.browser.after_hooks.add p }
    end

  end
end
