module Watirmark
  module Model
    class Default
      include Enumerable
      attr_accessor :model

      def initialize()
        @members = []
        # :zip is a method in Enumerable and if not stubbed out will
        # cause an issue when we have a model with an address
        # (this is in an instance_eval to quiet a rubymine warning)
        instance_eval "undef :zip"
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