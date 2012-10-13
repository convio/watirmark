module Watirmark

  # This functionality allows us to ignore and buffer
  # post failures and then compare on a cucumber step
  module CucumberPostFailureBuffering
    @@buffer_post_failure = false

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
        puts "Using firefox profile: #{Configuration.instance.default_firefox_profile}"
        profile = Selenium::WebDriver::Firefox::Profile.from_name Configuration.instance.default_firefox_profile
      else
        profile = Selenium::WebDriver::Firefox::Profile.new
      end
      profile.native_events = false
      profile
    end

    def newsession
      closebrowser
      openbrowser
    end

    def openbrowser
      config.webdriver ||= :firefox
      case config.webdriver.to_sym
        when :firefox
          Page.browser = Watir::Browser.new config.webdriver.to_sym, :profile => config.firefox_profile
        else
          Page.browser = Watir::Browser.new config.webdriver.to_sym
      end
      POST_WAIT_CHECKERS.each { |p| Page.browser.add_checker p }
      Page.browser.screenshot.base64
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
  end
end
