# This is a globally accessible static hash to
# store all models declared by the test automation. Making it available
# allows us to use the models values as table parameters in the gherkin!
DataModels = {}


module Watirmark
  module Transforms
    def self.new_model model_name, user_defined_name
      if model_exists?(user_defined_name)
        DataModels[user_defined_name]
      else
        DataModels[user_defined_name] = model_class(model_name).new(:model_name => user_defined_name)
      end
    end

    private

    def model_exists?(name)
      DataModels.has_key?(name)
    end

    def model_class(name)
      "#{name.split.map(&:camelize).join}Model".split('::').inject(Kernel) {|context, x| context.const_get x}
    end

  end
end

# Create a new models and add it to the DataModels hash
NEW_MODEL = Transform /^\[new (\S+) (\S+)\]$/ do |model_name, user_defined_name|
  model_name.chop! if model_name.end_with?(':')
  Watirmark::Transforms.new_model model_name, user_defined_name
end

OLD_STYLE_MODEL = Transform /^\[new ([^:]+): (\S+)\]$/ do |model_name, user_defined_name|
  model_name = model_name.camelize
  model_name.chop! if model_name.end_with?(':')
  Watirmark::Transforms.new_model model_name, user_defined_name
end

# Return the models from the collection of existing models
MODEL = Transform /^\[(\S+)\]$/ do |model_name|
  DataModels[model_name] ||= Struct.new(:model_name).new(model_name)
end

