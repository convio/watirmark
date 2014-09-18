module Watirmark
  class WatirmarkStatsCollection
    attr_reader :stats_list

    def initialize
      @stats_list ||= []
    end

    def start
      watirmark_statistics = WatirmarkStatistics.new
      @stats_list << watirmark_statistics
      watirmark_statistics
    end

    def stop(watirmark_statistics)
      @stats_list.delete(watirmark_statistics)
    end

    def method_missing(method_name, *args, &block)
      if WatirmarkStatistics.new.respond_to?(method_name) && !@stats_list.nil?
        @stats_list.each { |wm_stats| wm_stats.send(method_name, *args)}
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      WatirmarkStatistics.new.respond_to?(method_name) || super
    end

  end

  class WatirmarkStatistics
    def initialize
      @start_time = Time.now

      @clicks = 0
      @click_time = 0

      @text_input = 0
      @text_input_time = 0

      @found_elements = []
      @element_time = 0

      @error_checks = 0
      @error_time = 0

      @navigations = 0
      @navigation_time = 0

      @sleep_time = 0
    end

    attr_accessor :clicks, :click_time, :text_input, :text_input_time, :found_elements, :element_time, :error_checks, :error_time, :navigations, :navigation_time, :sleep_time

    def add_click
      @clicks += 1
    end

    def count_click_time(time)
      @click_time += time
    end


    def add_text_input
      @text_input += 1
    end

    def count_text_input_time(time)
      @text_input_time += time
    end


    def add_found_element(selector)
      @found_elements << selector
    end

    def count_element_time(time)
      @element_time += time
    end


    def add_error_check
      @error_checks += 1
    end

    def count_error_time(time)
      @error_time += time
    end


    def add_navigation
      @navigations += 1
    end

    def count_navigation_time(time)
      @navigation_time += time
    end

    def count_poll_time(time)
      @sleep_time += time
    end

    def total_known_time
      @navigation_time + @sleep_time + @element_time + @click_time + @error_time
    end

    def current_test_duration
      Time.now - @start_time
    end

    def results
      test_time = current_test_duration
    "\tTest Execution in: #{test_time.round(0)} seconds
    \tPolling sleeps for #{sleep_time.round(1)} seconds;\t\t\t\t\t#{(100*sleep_time/test_time).round(0)}% of test time
    \tNavigated #{navigations} times in #{navigation_time.round(1)} seconds;\t\t\t\t#{(100*navigation_time/test_time).round(0)}% of test time
    \tFound #{found_elements.size} elements in #{element_time.round(1)} seconds;\t\t\t\t#{(100*element_time/test_time).round(0)}% of test time
    \tClicked #{clicks} elements in #{click_time.round(1)} seconds;\t\t\t\t#{(100*click_time/test_time).round(0)}% of test time
    \tInputText #{text_input} times in #{text_input_time.round(1)} seconds;\t\t\t\t#{(100*text_input_time/test_time).round(0)}% of test time
    \tChecked for errors: #{error_checks} times in #{error_time.round(1)} seconds;\t#{(100*error_time/test_time).round(0)}% of test time
    \tUnknown time & overhead: #{(test_time - total_known_time).round(1)} seconds;\t\t\t#{(100*(test_time - total_known_time)/test_time).round(0)}% of test time\n"
    end
  end
end

module Watir
  module Wait

    class << self

      # WARNING - Overwritten Method
      def until(timeout = nil, message = nil, &block)
        timeout ||= Watir.default_timeout

        timer.wait(timeout) do
          result = yield(self)
          return result if result
          sleep INTERVAL
          Watirmark::Session.instance.watirmark_statistics.count_poll_time(INTERVAL)
        end

        raise TimeoutError, message_for(timeout, message)
      end
    end
  end

  class Element
    alias_method :old_click, :click
    alias_method :old_locate, :locate

    def click
      Watirmark::Session.instance.watirmark_statistics.add_click
      old_click
    end

    def locate
      Watirmark::Session.instance.watirmark_statistics.add_found_element(@selector)
      start_time = ::Time.now
      return_value = old_locate
      Watirmark::Session.instance.watirmark_statistics.count_element_time(::Time.now - start_time)
      return_value
    end

  end

  class ElementCollection
    alias_method :old_elements, :elements

    def elements
      start_time = ::Time.now
      return_value = old_elements
      Watirmark::Session.instance.watirmark_statistics.count_element_time(::Time.now - start_time)
      return_value.each {|element| Watirmark::Session.instance.watirmark_statistics.add_found_element(element) }
      return_value
    end
  end

  class IFrame
    alias_method :old_locate, :locate

    def locate
      Watirmark::Session.instance.watirmark_statistics.add_found_element(@selector)
      start_time = ::Time.now
      return_value = old_locate
      Watirmark::Session.instance.watirmark_statistics.count_element_time(::Time.now - start_time)
      return_value
    end
  end

  class Button
    alias_method :old_locate, :locate

    def locate
      Watirmark::Session.instance.watirmark_statistics.add_found_element(@selector)
      start_time = ::Time.now
      return_value = old_locate
      Watirmark::Session.instance.watirmark_statistics.count_element_time(::Time.now - start_time)
      return_value
    end
  end

  class Browser
    alias :old_old_run_checkers :run_checkers

    def run_checkers
      start_time = ::Time.now
      return_value = old_old_run_checkers
      Watirmark::Session.instance.watirmark_statistics.count_error_time(::Time.now - start_time)
      Watirmark::Session.instance.watirmark_statistics.add_error_check
      return_value
    end
  end

end

module Selenium
  module WebDriver
    module Remote

      class Bridge

        # WARNING - Overwritten Method
        def execute(*args)
          case args[0]
            when :sendKeysToElement
              Watirmark::Session.instance.watirmark_statistics.add_text_input
              text_input_start = ::Time.now
            when :sendKeysToActiveElement
              Watirmark::Session.instance.watirmark_statistics.add_text_input
              text_input_start = ::Time.now
            when :clickElement
              Watirmark::Session.instance.watirmark_statistics.add_click
              click_time_start = ::Time.now
            when :get
              Watirmark::Session.instance.watirmark_statistics.add_navigation
              nav_time_start = ::Time.now
            when :refresh
              Watirmark::Session.instance.watirmark_statistics.add_navigation
              nav_time_start = ::Time.now
            else
              no_start_time = true
          end

          return_value = raw_execute(*args)['value']

          unless no_start_time
            if text_input_start
              Watirmark::Session.instance.watirmark_statistics.count_text_input_time(::Time.now - text_input_start)
            elsif click_time_start
              Watirmark::Session.instance.watirmark_statistics.count_click_time(::Time.now - click_time_start)
            elsif nav_time_start
              Watirmark::Session.instance.watirmark_statistics.count_navigation_time(::Time.now - nav_time_start)
            end
          end

          return_value
        end
      end
    end
  end
end

