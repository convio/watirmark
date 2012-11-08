module Watirmark
  module Model
    class Default
      attr_accessor :model

      def initialize()
        @members = []
      end

      # This works around an issue that gets hit when
      # running from rake and the model has default.desc set.
      # If we don't have it here it thinks we're trying to call rakes' #desc
      def desc(&block)
        meta_def :desc do
          block
        end
      end

      def method_missing(name, &block)
        @members << name unless @members.include? name
        meta_def name do
          block
        end
      end

      def each
        @members.each {|i| yield i}
      end

    end
  end
end