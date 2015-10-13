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
    cloned_model = model.clone
    update_model(cloned_model, table)
    yield
  end
end

