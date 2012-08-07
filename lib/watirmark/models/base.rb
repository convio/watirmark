require_relative 'cucumber_helper'

module Watirmark
  module Model

    class Base < Class.new(Struct)
      include CucumberHelper

      class << self
        attr_accessor :search

        def default
          @default ||= Watirmark::Model::Default.new
        end

        def children
          @children ||= []
        end

        def model model
          raise Watirmark::ModelCreationError unless Class === model
          children << model
        end

        def search_term &block
          @search = block
        end
      end

      attr_accessor :default, :uuid, :model_name, :models, :parent, :children

      def initialize(params={})
        @default = self.class.default
        @children = []
        @search = self.class.search || Proc.new{nil}
        @params = params
        @uuid = generate_uuid
        @log = Logger.new STDOUT
        @log.formatter = proc {|severity, datetime, progname, msg| "#{msg}\n"}
        initialize_child_models
        reload_settings
        @log.info inspect
      end

      def initialize_child_models
        self.class.children.each {|child| @children << child.new}
      end

      def search_term
        instance_eval(&@search) || (parent.search_term if parent)
      end


      # this is a unique name that can be defined after the models is instantiated.
      # if the value changes, all initial settings are reloaded. This allows us
      # to set it during models creation in cucumber and make the fields take on
      # a string that we used to identify the models in the gherkin
      def model_name=(x)
        @model_name = x
        @uuid = generate_uuid @model_name
      end


      # add a submodel to the model after it has been instantiated
      def add_model(model)
        @children << model
        update_models
        @log.info "Added Model #{inspect}"
      end


      def find(model_class)
        return self if self.kind_of? model_class
        @children.each do |m|
          found_model = m.find model_class
          return found_model if found_model
        end
        return nil
      end

      def inspect
        model_details = " #{to_h}" unless to_h.empty?
        included_models = "\n   #{@children.flatten.map(&:inspect).join("\n   ")}" unless @children.empty?
        "#{model_class_name}#{model_details}#{included_models}"
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
        hash.each_pair { |key, value| send "#{key}=", value }
        self
      end

      # Update the model using the provided hash but only if exists (TODO: may not be needed any more)
      def update_existing_members hash
        hash.each_pair { |key, value| send "#{key}=", value if respond_to? "#{key}=".to_sym }
        self
      end

      def to_h
        h = {}
        each_pair do |name, value|
          begin
          if value.kind_of?(Proc)
            h[name] = instance_eval(&value) unless value.nil?
          else
            h[name] = value unless value.nil?
          end
          rescue NoMethodError => e
            h[name] = "[defined at runtime]"
          end
        end
        h
      end


      private


      def generate_uuid model_name=nil
        @uuid = (Watirmark::Configuration.instance.uuid ?
            model_name.to_s + Watirmark::Configuration.instance.uuid :
            model_name.to_s + UUID.new.generate(:compact)[0..9])
      end

      def reload_settings
        set_default
        update @params
        update_models
      end

      def set_default
        @default.each do |name|
          meta_def name do
            value = self[name.to_sym]
            # When a default refers to a default then we need this
            value.kind_of?(Proc) ? instance_eval(&value) : value
          end
          send "#{name}=", @default.send(name) if respond_to? "#{name}="
        end
      end

      def update_models
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
        if respond_to? method_name(model)
          meta_def collection_name(model).pluralize do
            @collection
          end
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
