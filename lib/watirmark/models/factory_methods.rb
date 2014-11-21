module Watirmark
  module Model
    module FactoryMethods
      attr_accessor :search, :model_type_name, :included_traits
      attr_writer :default, :keys

      def inherited(klass)
        unless self == Factory
          add_keywords_to_subclass klass
          add_defaults_to_subclass klass
          add_traits_to_subclass klass
        end
      end

      def default
        @default ||= DefaultValues.new
      end

      def keys
        @keys ||= []
      end

      def defaults(&block)
        default.instance_exec &block
      end

      def children
        @children ||= []
      end

      def model *models
        models.each { |model| raise Watirmark::ModelCreationError unless Class === model }
        @children = children + models
        @children.uniq!
      end

      def model_type(c_name)
        @model_type_name = c_name
      end

      def search_term &block
        @search = block
      end

      def traits(*names)
        @included_traits = [*names].flatten
      end

      def keywords(*args)
        @keys ||= []
        @keys += [*args].flatten
        @keys = @keys.uniq
      end

      private

      def add_keywords_to_subclass klass
        if @keys
          klass.keys = []
          klass.keys += @keys.dup
        end
      end

      def add_defaults_to_subclass klass
        klass.default = @default.dup if @default
      end

      def add_traits_to_subclass klass
        klass.included_traits = @included_traits.dup if @included_traits
      end

    end
  end
end
