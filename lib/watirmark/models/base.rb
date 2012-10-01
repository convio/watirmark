require_relative 'cucumber_helper'

module Watirmark
  module Model

    DebugModelValues = Hash.new{|h,k| h[k]=Hash.new}

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

        def include_defaults block
          block.call @default
        end

        def traits(t, *name)
          default if @default.nil?
          name.each do |n|
            t.declarations[n].call @default
          end
        end
      end



      attr_accessor :default, :uuid, :model_name, :models, :parent, :children

      def initialize(params={})
        if params[:model_name]
          @model_name = params[:model_name]
          params.delete(:model_name)
        end
        @params = params
        @children = self.class.children.map(&:new)
        @default = self.class.default
        @search = self.class.search || Proc.new{nil}
        @uuid = (Watirmark::Configuration.instance.uuid || UUID.new.generate(:compact)[0..9]).to_s
        @log = Logger.new STDOUT
        @log.formatter = proc {|severity, datetime, progname, msg| "#{msg}\n"}
        reload_settings
        @log.info inspect
      end


      # The search_term, used for a controller's search can be defined in this model
      # or will look in a parent's model. This allows us to define it once for a composed model
      def search_term
        instance_eval(&@search) || (parent.search_term if parent)
      end


      def add_model(model)
        @children << model
        create_model_methods
        @log.info "Added Model #{model.inspect} to #{model_name || model_class_name}"
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
        model_friendly_name = @model_name ? "#{@model_name}: " : nil
        model_details = " #{to_h}" unless to_h.empty?
        included_models = "\n   #{@children.flatten.map(&:inspect).join("\n   ")}" unless @children.empty?
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

      def model_name=(name)
        @model_name = name
        add_debug_overrides
      end


    private

      def reload_settings
        create_default_methods
        create_model_methods
        update @params
        add_debug_overrides
      end

      def add_debug_overrides
        return unless @model_name && DebugModelValues != {}
        warn "Adding DEBUG overrides for #{@model_name}"
        update DebugModelValues['*'] if DebugModelValues['*']
        update DebugModelValues[@model_name] if DebugModelValues[@model_name]
      end


      def create_default_methods
        @default.each do |name|
          meta_def name do
            normalize self[name.to_sym]
          end
          send "#{name}=", @default.send(name) if respond_to? "#{name}="
        end
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
