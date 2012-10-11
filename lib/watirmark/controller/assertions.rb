module Watirmark
  module Assertions
    
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
      @matcher ||= Watirmark::Matcher.new
      unless @matcher.matches(element, expected, actual)
        error = Watirmark::VerificationException.new(@matcher.error_message)
        error.actual = actual
        error.expected = expected
        raise error 
      end
    end
    
  end
end
