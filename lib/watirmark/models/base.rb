module Watirmark
  module Model

    module CucumberHelper

      def format_value(value)
        if String === value && value[0, 1].eql?("=") #straight eval
          eval(value[1..value.length])
        elsif value == "true"
          return true
        elsif value == "false"
          return false
        else
          insert_model(value)
        end
      end

      def insert_model(text)
        result = text
        regexp = /\[([^\]]+)\]\.(\w+)/
        while result =~ regexp #get value from models
          model_name = $1
          method     = $2
          value = DataModels.instance[model_name].send method.to_sym
          result.sub!(regexp, value.to_s)
        end
        result
      end

      def merge_cucumber_table(cuke_table)
        cuke_table.rows_hash.each do |key, value|
          send "#{key}=", format_value(value)
        end
        @log.info "Updated #{inspect}"
        self
      end

    end

    class Base < Class.new(Struct)
      include CucumberHelper

      attr_accessor :defaults, :name, :uuid, :model_name, :models

      class << self
        def models
          @models ||= []
        end

        def composed_fields
          @composed_fields ||= {}
        end

        def default
          @defaults ||= Watirmark::Model::Defaults.new
        end

        # create a read-only field that is a composition of multiple fields.
        # for example, full_name might be a composition of first and last names.
        def compose(name, &block)
          composed_fields[name] = block
        end

        def add_model(model)
          models << model
        end

        def uuid
          @uuid ||= generate_uuid
        end

        def generate_uuid model_name=nil
          @uuid = (Watirmark::Configuration.instance.uuid ?
                  model_name.to_s + Watirmark::Configuration.instance.uuid :
                  model_name.to_s + UUID.new.generate(:compact)[0..9])
        end

        def model_class_name
          name = self.inspect
          name = self.class.superclass if name.to_s =~ /Class/
          name = 'Model' if name.to_s =~ /Module/
          name.sub!(/.+::/,'')
          name
        end
      end


      def initialize(params={})
        @defaults = self.class.default
        @composed_fields = self.class.composed_fields
        @models = self.class.models
        @submodels ||= []
        @params = params
        @uuid = self.class.uuid
        @log = Logger.new STDOUT
        @log.formatter = proc {|severity, datetime, progname, msg| "#{msg}\n"}
        reload_settings
        @log.info inspect
      end


      # this is a unique name that can be defined after the models is instantiated.
      # if the value changes, all initial settings are reloaded. This allows us
      # to set it during models creation in cucumber and make the fields take on
      # a string that we used to identify the models in the gherkin
      def model_name=(x)
        @model_name = x
        @uuid = self.class.generate_uuid @model_name
        reload_settings
      end


      def model_class_name
        self.class.model_class_name
      end


      # add a submodel to the model after it has been instantiated
      def add_model(model)
        @models << model
        update_models
      end


      def find(model_class)
        return self if self.kind_of? model_class
        @models.each {|m| return m.find model_class}
        raise Watirmark::ModelNotFound, "unable to locate model #{model_class}"
      end

      # This method is used to test the models to see if the updates to the models
      # have already been applied. This allows the user to skip a step
      # if something has already been applied. Useful for rerunning scripts, eg.
      def includes? hash
        hash.each_pair { |key, value| return false unless send("#{key}") == value }
        true
      end

      # Update the models with the provided hash
      def update hash
        hash.each_pair { |key, value| send "#{key}=", value }
        self
      end



      # Update the models with the hash, only for members that exist in this models.
      # TODO: this may be unncessary after we add composition of models
      def update_existing_members hash
        hash.each_pair { |key, value| send "#{key}=", value if respond_to? "#{key}=".to_sym }
        self
      end

      def to_h
        h = {}
        each_pair { |name, value| h[name] = value unless value.nil? }
        h
      end

      def inspect
        model_details = " #{to_h}" unless to_h.empty?
        included_models = "\n   #{@models.flatten.map(&:inspect).join("\n   ")}" unless @models.empty?
        "#{model_class_name}#{model_details}#{included_models}"
      end



      private


      def reload_settings
        set_defaults
        define_composed_fields
        update @params
        update_models
      end

      def set_defaults
        @defaults.each do |name|
          next unless respond_to? "#{name}="
          val = @defaults.send(name)
          if val.kind_of?(Proc)
            send "#{name}=", instance_eval(&val)
          else
            send "#{name}=", val
          end
        end
      end


      def define_composed_fields
        @composed_fields.each_key do |method_name|
          meta_def method_name do                2
            instance_eval &@composed_fields[method_name]
          end
        end
      end

      def update_models
        @models.each do |model|

          method_name = model.model_class_name.to_s.sub(/Model$/, '').downcase
          @submodels << model unless @submodels.include? model

          # if there are more than one of a particular model present, create a collection
          # using the pluralized name of the model's class
          if respond_to? method_name
            meta_def method_name.pluralize do
              @submodels
            end
          end

          # Always create a singular method that returns the first item
          # whether or not there are a collection of models of that class
          unless respond_to? method_name
            meta_def method_name do
              model
            end
          end
        end
      end
    end
  end
end
