require 'watirmark/page/page'
if Watirmark::Configuration.instance.webdriver
  require 'watir-webdriver'
else
  require 'watir'
end

module Watirmark
  
  # This class manages a browser
  class IESession
    include Singleton

    POST_WAIT_CHECKERS = []
    @@browser = nil
    @@logged_in = false  #used for autologin on --continue
    @@buffer_post_failure = false

    def browser; @@browser; end
    def browser=(x); @@browser=x; ::Page.browser=x end
    def logged_in; @@logged_in; end
    def logged_in=(x); @@logged_in = x; end
    def post_failure; @@post_failure; end
    def post_failure=(x); @@post_failure = x; end
    def buffer_post_failure; @@buffer_post_failure; end

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
      Watir::IE.attach_timeout = 5 unless config.webdriver
      Watirmark.add_exit_task {
        closebrowser if config.closebrowseronexit
      }
      config.firefox_profile = default_firefox_profile if config.webdriver == 'firefox'
    end

    def default_firefox_profile
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.native_events = false
      profile
    end

    def newsession
      closebrowser
      openbrowser
    end

    def openbrowser
      config.session = true
      initialize_browser unless @@browser
      self.browser = @@browser
      @@browser
    end

    # Set up @@browser
    def initialize_browser
      if config.webdriver
        case config.webdriver.to_sym
        when :firefox
          @@browser ||= Watir::Browser.new config.webdriver.to_sym, :profile => config.firefox_profile
        else
          @@browser ||= Watir::Browser.new config.webdriver.to_sym
        end
      else
        Watir::IE.visible = !!config.visible
        @@browser = Watir::IE.find(:title, attach_title) if config.attach
        @@browser ||= Watir::IE.new_process
        @@browser.speed = config.speed
        if Watir.constants.include?('VERSION') && Watir::VERSION =~ /1\.(8|9)/
          @@browser.disable_waiter(:ie_busy) if  @@browser.waiters.include? :ie_busy
        end
      end
      POST_WAIT_CHECKERS.each {|p| @@browser.add_checker p}
      nil
    end
    private :initialize_browser
    
    attr_writer :attach_title
    def attach_title
      if ENV['watir_browser'] == 'firefox'
        default = /.*/
      else
        default = //
      end
      @attach_title || default 
    end
    private :attach_title
    
    def closebrowser
      @@browser.close if @@browser
      @@browser = nil
      config.session = false
      config.loggedin = false
    end

  end
end
