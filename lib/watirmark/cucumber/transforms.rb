# This is a globally accessible static hash to
# store all models declared by the test automation. Making it available
# allows us to use the models values as table parameters in the gherkin!
DataModels = {}


module Watirmark
  module Transforms
    def self.new_model model_name, user_defined_name
      model_name = "#{model_name.split.map(&:camelize).join}Model"
      if DataModels.has_key?(user_defined_name)
        return DataModels[user_defined_name] unless (DataModels[user_defined_name].class.to_s =~ /Class:/)
      end
      # Get the reference to the class
      model_class = model_name.split('::').inject(Kernel) {|context, x| context.const_get x}
      model = model_class.new(:model_name => user_defined_name)
      DataModels[user_defined_name] = model
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

