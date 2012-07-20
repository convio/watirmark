module Watirmark
  module Model
    module ClassMethods
      attr_reader :defaults, :composed_fields, :models

      def self.extended(klass)
        klass.instance_variable_set '@composed_fields', {}
        klass.instance_variable_set '@defaults', Watirmark::Model::Defaults.new
        klass.instance_variable_set '@models', []
      end

      # set default settings for struct members
      def default
        @defaults
      end

      # create a read-only field that is a composition of multiple fields.
      # for example, full_name might be a composition of first and last names.
      def compose name, &block
        @composed_fields[name] = block
      end

      def add_model(name)
        @models << name
      end
    end
  end
end
