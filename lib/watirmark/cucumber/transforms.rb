module Watirmark
  module Transforms
    def self.new_model model_name, user_defined_name
      model_name = "#{model_name}Model".camelcase
      DataModels.instance ||= {}
      unless DataModels.instance.has_key?(user_defined_name)
        model_class = TransformHelper.find_class_by_name(model_name.to_sym)
        model = model_class.new
        model.model_name = user_defined_name
        DataModels.instance[user_defined_name] = model
      end
      DataModels.instance[user_defined_name]
    end
  end
end

# Create a new models and add it to the DataModels hash
NEW_MODEL = Transform /^\[new ([^:]+): (\S+)\]$/ do |model_name, user_defined_name|
  Watirmark::Transforms.new_model model_name, user_defined_name
end

NEW_NAMESPACED_MODEL = Transform /^\[new (\w+::\w+) (\S+)\]$/ do |model_name, user_defined_name|
  Watirmark::Transforms.new_model model_name, user_defined_name
end

# Return the models from the collection of existing models
MODEL = Transform /^\[(\S+)\]$/ do |model_name|
  DataModels.instance ||= {}
  raise "#{model_name} is not a defined models!" unless DataModels.instance[model_name]
  DataModels.instance[model_name]
end

