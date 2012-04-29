module Watirmark
  class Matcher
    
    class << self
      attr_accessor :matcher
      
      def add_matcher(x, &block)
        @matcher ||= {}
        @matcher[x] = block
      end

      def is_number?(object)
        true if Float(object) rescue false
      end
    end
    
    add_matcher('nil')      { @actual.to_s.strip == '' }
    add_matcher('!nil')     { @actual.to_s.strip != '' }
    add_matcher('enabled')  { @element.disabled? == false }
    add_matcher('disabled') { @element.disabled? == true }
    add_matcher('exist')    { @element.exists? == true && @element.visible? == true }
    add_matcher('exists')   { @element.exists? == true && @element.visible? == true}
    add_matcher('!exist')   { @element.exists? == false || @element.visible? == false}
    add_matcher('!exists')  { @element.exists? == false || @element.visible? == false}

    def matcher
      self.class.matcher 
    end

    def error_message
      kwd = @element.keyword if @element.respond_to?(:keyword)
      message = "#{ kwd || @element.name}: expected '#{@expected.to_s}' (#{@expected.class})"
      if !matcher.has_key?(@expected.to_s)
        message += " got '#{@actual.to_s}' (#{@actual.class})"
      end
      message
    end  

    def matches(element, expected, actual)
      @element = element
      @expected = expected
      @actual = actual

      @expected = @expected.to_f if self.class.is_number?(@expected)
      case @expected
      when Regexp
        should_match_regexp
      when Float, Fixnum, Bignum, Integer, Rational
        should_match_number
      else
        if matcher.has_key?(@expected.to_s)
          instance_eval(&matcher[@expected.to_s])
        elsif normalize_value(@expected.to_s) == normalize_value(@actual.to_s)
          true
        else
          false
        end
      end
    end

    def normalize_value(x)
      result = x.dup # in case it was frozen
      if result.strip != '' # clean up spaces and line endings unless it's just spaces
        result.gsub!("\r\n","\n")
        result.strip!
      end
      if result =~ /^[0-9]{1,2}[-\/][0-9]{1,2}[-\/][0-9]{2,4}$/ || result =~ /^[0-9]{2,4}[-\/][0-9]{1,2}[-\/][0-9]{1,2}$/ # translate dates to a Date object
        result = Date.parse(result)
      end
      # strip sign from dollar amounts
      if result =~ /^\$([\d\.]+)/
        result = $1
      end
      result
    end
    
    def should_match_regexp
      @expected.matches(@actual.to_s)
    end
    
    def should_match_number
      @expected == @actual.to_s.gsub(/[,$]/,'').to_f
    end
    
  end
end
