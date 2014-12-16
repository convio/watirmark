require_relative 'cucumber_helper'
require_relative 'default_values'
require_relative 'factory_methods'
require_relative 'factory_method_generators'
require_relative 'debug_methods'

module Watirmark
  module Model

    class Factory
      extend FactoryMethods

      include CucumberHelper
      include DebugMethods
      include FactoryMethodGenerators

      attr_accessor :defaults, :model_name, :models, :parent, :children, :model_type
      attr_reader   :keywords

      def marshal_dump
        [@keywords, @model_name, @models, @parent, @children, @model_type, self.to_h]
      end

      def marshal_load(obj)
        keyword_values = obj.pop
        @keywords, @model_name, @models, @parent, @children, @model_type = obj
        update keyword_values
      end

      def initialize(params={})
        @params = params
        @model_type = self.class.model_type_name
        @search     = self.class.search || Proc.new{nil}
        @keywords   = self.class.keys.dup || []
        @children   = self.class.children.dup.map(&:new)
        set_model_name
        set_default_values
        create_model_getters_and_setters
        set_initial_values
        Watirmark.logger.info inspect
      end

      def uuid
        @uuid ||= (Watirmark::Configuration.instance.uuid || UUID.new.generate(:compact)[0..9]).to_s
      end

      def hash_id(size = nil, type = :hex)
        size = size || Watirmark::Configuration.instance.hash_id_length || 8
        seed = Watirmark::Configuration.instance.hash_id_seed || "Watirmark Default Seed"
        @hash_id ||= generate_hash_id seed, size, type
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
        create_child_methods
        Watirmark.logger.info "Added Model #{model.inspect} to #{model_name || model_class_name}"
        return self
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
        remove_empty_entries hash
        hash.each_pair { |key, value| send "#{key}=", value }
        self
      end


      # Update the model using the provided hash but only if exists (TODO: may not be needed any more)
      def update_existing_members hash
        remove_empty_entries hash
        hash.each_pair { |key, value| send "#{key}=", value if respond_to? "#{key}=".to_sym }
        self
      end

      def remove_empty_entries hash
        hash.delete_if {|k| k.nil? || k == ':' || k =~ /^\s+$/ || k.empty?}
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

      def unique_instance_name
        class_name = self.class.name[/([^\:]+)Model$/i,1]
        model_name_exists = model_name.nil? ? false : (not model_name.empty?)
        unique_name = model_name_exists ? model_name : class_name.downcase
        unique_name_with_uuid = unique_name + "_" + uuid
      end

    private

      def set_model_name
        if @params[:model_name]
          @model_name = @params[:model_name]
          @params.delete(:model_name)
        end
      end

      def create_model_getters_and_setters
        create_keyword_methods
        create_child_methods
      end

      def set_default_values
        @defaults = self.class.default.dup
        @traits = self.class.included_traits || []
        include_defaults_from_traits @traits
      end

      def set_initial_values
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

      def method_name model
        model.model_class_name.to_s.sub(/Model$/, '').underscore
      end

      def generate_hash_id(seed, size=8, type = :hex)
        seed_int = seed.scan(/./).inject(1) { |product, chr| product * chr.ord }
        prng     = Random.new(seed_int)
        if type == :alpha
          o = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
        else #:hex
          o = ('a'..'f').to_a + (0..9).to_a
        end
        (0...size.to_i).map { o.sample(random: prng) }.join
      end

    end
  end
end
