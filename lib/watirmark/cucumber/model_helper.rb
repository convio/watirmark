module ModelHelper
  def add_model_debug_values(table)
    table.raw.each do |row|
      DebugModelValues[row[0]][row[1]] = row[2]
    end
  end

  def update_model(model, table)
    model.update(hash_record(table))
  end

  def with_updated_model(model, table)
    unless model.includes?(hash_record(table))
      update_model(model, table)
      yield
      Watirmark.logger.info "Updated models '#{model.model_name}':\n#{hash_record(table).inspect}"
    end
  end

# Perform an action using a models and update
# the models if that action is successful
  def with_model(model, table)
    orig_model = model.clone
    update_model(model, table)
    yield
    if Watirmark::Session.instance.post_failure
      Watirmark.logger.info  "Reverting Model #{Watirmark::Session.instance.post_failure}"
      model.update(orig_model.to_h) # revert models on failure
    elsif model.to_h != orig_model.to_h
      Watirmark.logger.info "Updated model '#{model.model_name}' #{hash_record(table).inspect}"
    end
  end
end

