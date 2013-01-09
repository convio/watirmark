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

    def catch_post_failures(&block)
      @@post_failure = nil
      @@buffer_post_failure = true
      block.call
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
        closebrowser if config.closebrowseronexit
      }
      config.firefox_profile = default_firefox_profile if config.webdriver.to_s == 'firefox'
    end

    def default_firefox_profile
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
        profile['browser.helperApps.neverAsk.saveToDisk'] = "text/csv,application/pdf"
        profile['security.warn_entering_secure'] =  false
        profile['security.warn_submit_insecure'] = false
        profile['security.warn_entering_secure.show_once'] = false
        profile['security.warn_entering_weak'] =  false
        profile['security.warn_entering_weak.show_once'] =  false
        profile['security.warn_leaving_secure'] =  false
        profile['security.warn_leaving_secure.show_once'] =  false
        profile['security.warn_viewing_mixed'] =  false
        profile['security.warn_viewing_mixed.show_once'] =  false
      end
      profile
    end

    def newsession
      closebrowser
      openbrowser
    end

    def openbrowser
      Page.browser = new_watir_browser
      initialize_page_checkers
      initialize_screenshots
      Page.browser
    end

    def closebrowser
      begin
        Page.browser.close
      rescue Errno::ECONNREFUSED
        # browser already closed or unavailable
      ensure
        Page.browser = nil
      end
    end

    private

    def new_watir_browser
      config.webdriver ||= :firefox
      if config.webdriver.to_sym == :firefox
        Watir::Browser.new config.webdriver.to_sym, :profile => config.firefox_profile
      else
        Watir::Browser.new config.webdriver.to_sym
      end
    end

    def initialize_screenshots
      Page.browser.screenshot.base64
    end

    def initialize_page_checkers
      POST_WAIT_CHECKERS.each { |p| Page.browser.add_checker p }
    end

  end
end
