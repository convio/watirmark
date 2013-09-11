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
      @headless = Headless.new if config.headless
      Watirmark.add_exit_task {
        closebrowser if config.closebrowseronexit
        @headless.destroy if config.headless
      }
      config.firefox_profile = default_firefox_profile if config.webdriver.to_s == 'firefox'
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
      profile
    end

    def newsession
      closebrowser
      @headless.start if config.headless
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
      rescue Errno::ECONNREFUSED, Selenium::WebDriver::Error::WebDriverError
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
