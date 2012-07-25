module Watirmark
  module Model

    class Simple < Class.new(Struct)
      attr_accessor :defaults, :name, :uuid, :model_name, :models

      class << self
        def models
          @models ||= Hash.new{|h,k| h[k]=Array.new}
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

        def add_model(name)
          models[name.class] << name
        end

        def uuid
          @uuid ||= generate_uuid
        end

        def generate_uuid model_name=nil
          @uuid = (Watirmark::Configuration.instance.uuid ?
                  model_name.to_s + Watirmark::Configuration.instance.uuid :
                  model_name.to_s + UUID.new.generate(:compact)[0..9])
        end
      end

      def initialize(params={})
        @defaults = self.class.default
        @composed_fields = self.class.composed_fields
        @models = self.class.models
        @params = params
        @uuid = self.class.uuid
        reload_settings
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


      private

      def reload_settings
        set_defaults
        define_composed_fields
        update @params
        add_models
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
          meta_def method_name do
            instance_eval &@composed_fields[method_name]
          end
        end
      end

      def add_models
        @models.each_key do |model_class|
          # if there are more than one of a particular model present, create a collection
          # using the pluralized name of the model's class
          if @models[model_class].size > 1
            method_name = model_class.to_s.sub(/Model$/, '').downcase.pluralize
            meta_def method_name do
              @models[model_class]
            end
          end

          # Always create a singular method that returns the first item
          # whether or not there are a collection of models of that class
          method_name = model_class.to_s.sub(/Model$/, '').downcase
          meta_def method_name do
            @models[model_class].first
          end
        end
      end
    end
  end
end
