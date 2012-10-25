module Watirmark
  module Assertions

    private

    def assert_equal(element, expected)
      return if expected.nil?
      
      element.extend KeywordMethods
      if map = element.radio_map
        expected = map.lookup(expected)
      end
      
      actual = actual_value element, expected
      compare_values(element, expected, actual)
    end

    # Returns the user visible value of the element.
    def actual_value element, expected=nil
      case element
        when Watir::Select
          element.selected_options.first.text
        when Watir::CheckBox
          element.set?
        when Watir::Radio
          if element.set?(expected)
            expected
          else
            element.value
          end
        when Watir::TextField
          element.value
        else
          if element.respond_to?(:value) && element.value != ''
            element.value
          else
            element.text
          end
      end
    end
    
    def assert(result)
      unless result
        raise Watirmark::VerificationException, "Expected true got #{result}"
      end
    end
    
    def compare_values(element, expected, actual)
      if Matcher.exists?(expected)
        fail(element, expected, actual) unless Matcher.matches?(element, expected, actual)
      else
        fail(element, expected, actual) unless matches?(expected, actual)
      end
    end

    def fail(element, expected, actual)
      error = Watirmark::VerificationException.new(error_message(element, expected, actual))
      error.actual = actual
      error.expected = expected
      raise error
    end

    def error_message(element, expected, actual)
      kwd = element.keyword if element.respond_to?(:keyword)
      message = "#{ kwd || element.name}: expected '#{expected.to_s}' (#{expected.class})"
      message += " got '#{actual.to_s}' (#{actual.class})"
      message
    end

    def is_number?(object)
      true if Float(object) rescue false
    end

    def matches?(expected, actual)
      expected = expected.to_f if is_number?(expected)
      case expected
        when Regexp
          should_match_regexp(expected, actual)
        when Float, Fixnum, Bignum, Integer, Rational
          should_match_number(expected, actual)
        else
          if normalize_value(expected.to_s) == normalize_value(actual.to_s)
            true
          else
            false
          end
      end
    end

    def normalize_value(x)
      result = x.dup
      if result.strip != ''
        result.gsub!("\r\n","\n")
        result.strip!
      end

      # handle dates
      if result =~ /^[0-9]{1,2}[-\/][0-9]{1,2}[-\/][0-9]{2,4}$/ || result =~ /^[0-9]{2,4}[-\/][0-9]{1,2}[-\/][0-9]{1,2}$/ # translate dates to a Date object
        result = Date.parse(result)
      end

      # strip sign from dollar amounts
      if result =~ /^\$([\d\.]+)/
        result = $1
      end
      result
    end

    def should_match_regexp(expected, actual)
      expected.matches(actual.to_s)
    end

    def should_match_number(expected, actual)
      expected == actual.to_s.gsub(/[,$]/,'').to_f
    end
  end
end
