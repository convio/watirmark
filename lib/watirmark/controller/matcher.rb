module Watirmark
  class Matcher
    class << self
      @@matchers = {}

      def add_matcher(name, &block)
        @@matchers[name] = block
      end

      def exists?(name)
        @@matchers.has_key?(name)
      end

      def matches?(element, expected, actual)
        instance_exec(element, actual, &@@matchers[expected])
      end
    end
  end
end