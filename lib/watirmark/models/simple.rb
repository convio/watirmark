module Watirmark
  module Model
    module Simple
      attr_reader :defaults, :name, :uuid, :model_name

      def self.included(klass)
        klass.extend Watirmark::Model::ClassMethods
      end

      def initialize(params={})
        @defaults = self.class.defaults
        @composed_fields = self.class.composed_fields
        @models = self.class.models
        @params = params
        reload_settings
      end

      # this is a unique name that can be defined after the model is instantiated.
      # if the value changes, all initial settings are reloaded. This allows us
      # to set it during model creation in cucumber and make the fields take on
      # a string that we used to identify the model in the gherkin
      def model_name=(x)
        @model_name = x
        reload_settings
      end

      def models
        model_list = [self]
        @models.each{|x| model_list += x.models}
        model_list.flatten.uniq
      end

      # This method is used to test the model to see if the updates to the model
      # have already been applied. This allows the user to skip a step
      # if something has already been applied. Useful for rerunning scripts, eg.
      def includes? hash
        hash.each_pair { |key, value| return false unless send("#{key}") == value }
        true
      end


      # Update the model with the provided hash
      def update hash
        hash.each_pair { |key, value| send "#{key}=", value }
        self
      end


      # Update the model with the hash, only for members that exist in this model.
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
        generate_uuid
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


      # Generate a UUID for the instantiation of the model
      # This id should be used in cases where the data needs to be
      # unique for each test execution
      def generate_uuid
        if Watirmark::Configuration.instance.uuid
          @uuid = @model_name.to_s + Watirmark::Configuration.instance.uuid
        else
          @uuid = @model_name.to_s + UUID.new.generate(:compact)
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
        @models.each do |model|
          method_name = model.class.to_s.sub(/Model$/, '').downcase
          meta_def method_name do
            model
          end
        end
      end
    end
  end
end
