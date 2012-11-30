module Watirmark
  module Model
    module FactoryMethodGenerators

      # Act like an OpenStruct so we can be backward compatible with older controllers
      def method_missing(key, *args, &block)
        create_getters_and_setters strip_equals_from_method_name(key)
        send key, *args
      end

      private

      def create_keyword_methods
        @keywords.each do |key|
          create_getters_and_setters key
          set_default_value key
        end
      end

      def create_getters_and_setters key
        @keywords << key unless @keywords.include? key #handle call from method_missing
        create_getter_method key
        create_setter_method key
      end

      def create_getter_method(key)
        meta_def key do
          normalize instance_variable_get("@#{key}")
        end
      end

      def create_setter_method(key)
        meta_def "#{key}=" do |value|
          instance_variable_set "@#{key}", value
        end
      end

      def set_default_value key
        send("#{key}=", get_default_value(key)) if send(key).nil?
      end

      def get_default_value(key)
        @defaults.key?(key) ? @defaults[key] : nil
      end

      # if the value is a proc, evaluate it, otherwise just return
      def normalize(val)
        val.kind_of?(Proc) ? instance_eval(&val) : val
      end


      def create_child_methods
        @children.each do |model|
          model.parent = self
          create_model_collection model
          create_model_method model
        end
      end

      def collection_name model
        method_name(model).pluralize
      end


      def create_model_collection model
        @collection ||= []
        @collection << model unless @collection.include? model
        meta_def collection_name(model).pluralize do
          @collection
        end
      end


      def create_model_method model
        unless respond_to? method_name(model)
          meta_def method_name(model) do
            model
          end
        end
      end
    end
  end
end

