module Watirmark
  module Model
    class Default
      include Enumerable
      attr_accessor :model

      def initialize()
        @members = []
      end

      def method_missing(name, &block)
        @members << name unless @members.include? name
        meta_def name do
          puts caller[0]
          block
        end
      end

      def each
        @members.each {|i| yield i}
      end
    end
  end
end