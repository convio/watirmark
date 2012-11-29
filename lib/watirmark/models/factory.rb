require_relative 'cucumber_helper'
require_relative 'default_values'

module Watirmark
  module Model

    DebugModelValues = Hash.new{|h,k| h[k]=Hash.new}

    class Factory
      include CucumberHelper

      class << self

        attr_accessor :search, :model_type_name, :keys, :included_traits, :default

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

        def defaults(&block)
          default.instance_exec &block
        end

        def children
          @children ||= []
        end

        def model *models
          models.each {|model| raise Watirmark::ModelCreationError unless Class === model }
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
          @keys = [*args].flatten
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

      attr_accessor :defaults, :model_name, :models, :parent, :children, :model_type
      attr_reader   :keywords

      def initialize(params={})
        @params     = params
        set_instance_variables_from_factory_definition
        extract_model_name_from_params
        initialize_model_values
        Watirmark.logger.info inspect
      end

      def set_instance_variables_from_factory_definition
        @children   = self.class.children.map(&:new)
        @defaults   = self.class.default
        @keywords   = self.class.keys || []
        @traits     = self.class.included_traits || []
        @search     = self.class.search || Proc.new{nil}
        @model_type = self.class.model_type_name
      end

      def uuid
        @uuid ||= (Watirmark::Configuration.instance.uuid || UUID.new.generate(:compact)[0..9]).to_s
      end

      # Act like an OpenStruct so we work backward compatible
      def method_missing(key, *args, &block)
        strip_equals_from_method_name(key)
        @keywords << key
        create_getter_method key
        create_setter_method key
        send "#{key}=", nil
      end

      def strip_equals_from_method_name(method)
        method.to_s.delete('=').to_sym
      end

      # The search_term, used for a controller's search can be defined in this model
      # or will look in a parent's model. This allows us to define it once for a composed model
      def search_term
        instance_eval(&@search) || (parent.search_term if parent)
      end


      def add_model(model)
        @children << model
        create_model_methods
        Watirmark.logger.info "Added Model #{model.inspect} to #{model_name || model_class_name}"
      end


      def find(model_class)
        return self if self.kind_of? model_class
        @children.each do |m|
          return m if m.model_type == model_class
          found_model = m.find model_class
          return found_model if found_model
        end
        nil
      end


      def inspect
        model_friendly_name = @model_name ? "#@model_name: " : nil
        model_details = " #{to_h}" unless to_h.empty?
        included_models = "\n   #{@children.map(&:inspect).join("\n   ")}" unless @children.empty?
        "#{model_friendly_name}#{model_class_name}#{model_details}#{included_models}"
      end


      def model_class_name
        name = self.class.inspect.to_s
        name = self.class.superclass.to_s if name.to_s =~ /Class/
        name = 'Model' if name.to_s =~ /Module/
        name.sub!(/.+::/,'')
        name
      end


      def includes? hash
        hash.each_pair { |key, value| return false unless send("#{key}") == value }
        true
      end


      # Update the model using the provided hash
      def update hash
        hash.delete('')
        hash.each_pair { |key, value| send "#{key}=", value }
        self
      end


      # Update the model using the provided hash but only if exists (TODO: may not be needed any more)
      def update_existing_members hash
        hash.delete('')
        hash.each_pair { |key, value| send "#{key}=", value if respond_to? "#{key}=".to_sym }
        self
      end

      def model_name=(name)
        @model_name = name
        add_debug_overrides
      end


      def to_h
        h = {}
        @keywords.each do |key|
          begin
            name = key
            value = send(key)
            if value.kind_of?(Proc)
              h[name] = instance_eval(&value) unless value.nil?
            else
              h[name] = value unless value.nil?
            end
          rescue NoMethodError
            h[name] = "[defined at runtime]"
          end
        end
        h
      end


    private

      def extract_model_name_from_params
        if @params[:model_name]
          @model_name = @params[:model_name]
          @params.delete(:model_name)
        end
      end

      def initialize_model_values
        include_defaults_from_traits @traits
        create_keyword_methods
        create_model_methods
        update @params
        add_debug_overrides
      end


      def include_defaults_from_traits(traits)
        traits.each do |trait_name|
          trait = Watirmark::Model::Traits.instance[trait_name]
          trait.defaults.each {|k, v| @defaults[k] = v unless @defaults.key?(k)}
          trait.traits.each {|t| include_defaults_from_traits([t])}
        end
      end

      def create_keyword_methods
        @keywords.each do |key|
          create_getter_method key
          create_setter_method key
          set_default_value key
        end
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

      def add_debug_overrides
        return unless @model_name && DebugModelValues != {}
        Watirmark.logger.warn "Adding DEBUG overrides for #@model_name"
        update DebugModelValues['*'] if DebugModelValues['*']
        update DebugModelValues[@model_name] if DebugModelValues[@model_name]
      end


      # if the value is a proc, evaluate it, otherwise just return
      def normalize(val)
        val.kind_of?(Proc) ? instance_eval(&val) : val
      end


      def create_model_methods
        @children.each do |model|
          model.parent = self
          create_model_collection model
          create_model_method model
        end
      end


      def method_name model
        model.model_class_name.to_s.sub(/Model$/, '').underscore
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
