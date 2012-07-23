module ModelHelper

  def update_model(model, table)
    model.update(hash_record(table))
  end

  def with_updated_model(model, table, &block)
    unless model.includes?(hash_record(table))
      update_model(model, table)
      block.call
      log.info "Updated models '#{model.__name__}':\n#{hash_record(table).inspect}"
    end
  end

# Perform an action using a models and update
# the models if that action is successful
  def with_model(model, table, &block)
    orig_model = model.clone
    update_model(model, table)
    block.call
    if Watirmark::IESession.instance.post_failure
      log.info  "Reverting Model: #{Watirmark::IESession.instance.post_failure}"
      model.update(orig_model.to_h) # revert models on failure
    elsif model.to_h != orig_model.to_h
      log.info "Updated models '#{model.__name__}':\n#{hash_record(table).inspect}"
    end
  end
end

