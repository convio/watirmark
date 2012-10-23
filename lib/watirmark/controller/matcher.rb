module Watirmark
  class Matcher
    class << self
      def add_matcher(name, &block)
        @@matchers ||= {}
        @@matchers[name] = block
      end
    end

    def initialize(name)
      @name = name
      raise Waitmark::MatcherNotFound, "Matcher not defined for '#{@name}'"
    end

    def matches?(element, actual)
      instance_exec(element, actual, @@matchers[@name])
    end
  end
end