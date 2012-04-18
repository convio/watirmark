# Create a new model and add it to the DataModels hash
NEW_MODEL = Transform /^\[new ([^:]+): (\S+)\]$/ do |model_name, user_defined_name|
  model_name = "#{model_name}Model".camelcase
  DataModels.instance ||= {}
  unless DataModels.instance.has_key?(user_defined_name)
    model_class = TransformHelper.find_class_by_name(model_name.to_sym)
    DataModels.instance[user_defined_name] = model_class.new
    DataModels.instance[user_defined_name].__name__ = user_defined_name
    log.info("Declared model '#{user_defined_name}' using #{model_class}:\n#{DataModels.instance[user_defined_name].to_h.inspect}")
  end
  DataModels.instance[user_defined_name]
end

# Return the model from the collection of existing models
MODEL = Transform /^\[(\S+)\]$/ do |model_name|
  DataModels.instance ||= {}
  raise "#{model_name} is not a defined model!" unless DataModels.instance[model_name]
  DataModels.instance[model_name]
end

