require 'watirmark/page/page'
require 'watir-webdriver'

module Watirmark

  # This class manages a browser
  class Session
    include Singleton

    POST_WAIT_CHECKERS = []
    @@logged_in = false #used for autologin on --continue
    @@buffer_post_failure = false

    def browser
      Page.browser
    end

    def browser=(x)
      Page.browser = x
    end

    def logged_in
      @@logged_in
    end

    def logged_in=(x)
      @@logged_in = x
    end

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

    def config
      Watirmark::Configuration.instance
    end

    # set up the global variables, reading from the config file
    def initialize
      @@post_failure = nil
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
      config.session = true
      case config.webdriver.to_sym
        when :firefox
          browser = Watir::Browser.new config.webdriver.to_sym, :profile => config.firefox_profile
        else
          browser = Watir::Browser.new config.webdriver.to_sym
      end
      POST_WAIT_CHECKERS.each { |p| browser.add_checker p }
      browser.screenshot.base64
      browser
    end

    def closebrowser
      begin
        browser.close if browser
      rescue Errno::ECONNREFUSED
        # browser already closed or unavailable
      end
      browser = nil
      config.session = false
      config.loggedin = false
    end
  end
end
