require 'singleton'
module Watirmark
  module Model
    def self.trait(name, &block)
      new_trait = Trait.new
      new_trait.instance_eval(&block)
      Watirmark::Model::Traits.instance[name] = new_trait
    end

    class Trait
      attr_accessor :defaults

      def initialize
        @defaults = {}
        @traits = []
      end

      def traits(*names)
        if names.empty?
          @traits
        else
          @traits += names
        end
      end

      def method_missing(sym, *args, &block)
        @defaults[sym] = block
      end
    end

    class Traits < Hash
      include Singleton
    end
  end
end