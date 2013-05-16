module Watirmark
  module Actions

    attr_accessor :records

    def run(*actions)
      begin
        run_callback_method :before_all
        record_list.each do |record|
          create_model(record)
          execute_actions(actions)
        end
        run_callback_method :after_all
      ensure
        clear_record_list
      end
    end

    def search_for_record
      if @search
        search_controller = @search.new(@supermodel)
        if search_controller.respond_to?(:current_record_visible?)
          return if search_controller.current_record_visible?
        end
        search_controller.create
      end
    end

    def populate_data_overridden?
      self.class.instance_method(:populate_data).owner == self.class
    end

    def check_for_noop_populate
      @log           = Configuration.instance.logger
      @log.warn "Warning: Expected to populate values but none were provided" unless @seen_value || populate_data_overridden?
    end

    # Navigate to the View's edit page and for every value in
    # the models hash, verify that the html element has
    # the proper value for each keyword
    def verify
      search_for_record
      @view.edit @model
      verify_data
    end

    # Navigate to the View's edit page and
    # verify all values in the models hash
    def edit
      search_for_record
      @view.edit @model
      populate_data
      check_for_noop_populate
    end

    # Navigate to the View's create page and
    # populate with values from the models hash
    def create
      @view.create @model
      populate_data
      check_for_noop_populate
    end


    def verify_until(&block)
      run_with_stop_condition(:verify, block)
    end

    def edit_until(&block)
      run_with_stop_condition(:edit, block)
    end

    def create_until(&block)
      run_with_stop_condition(:create, block)
    end

    # Navigate to the View's create page and
    # populate with values from the models hash
    def get
      unless @view.exists? @model
        @view.create @model
        populate_data
      end
    end

    def delete
      @view.delete @model
    end

    def copy
      @view.copy @model
    end

    def restore
      @view.restore @model
    end

    def archive
      @view.archive @model
    end

    def publish
      @view.publish @model
    end

    def unpublish
      @view.unpublish @model
    end

    def activate
      @view.activate @model
    end

    def deactivate
      @view.deactivate @model
    end

    def locate_record
      @view.locate_record @model
    end

    # Navigate to the View's create page and verify
    # against the models hash. This is useful for making
    # sure that the create page has the proper default
    # values and contains the proper elements
    def check_defaults
      @view.create @model
      verify_data
    end

    alias :check_create_defaults :check_defaults


    # A helper function for translating a string into a
    # pattern match for the beginning of a string
    def starts_with(x)
      /^#{Regexp.escape(x)}/
    end

    # Stubs so converted XLS->RSPEC files don't fail
    def before_all;
    end

    def before_each;
    end

    def after_all;
    end

    def after_each;
    end

    private

    def run_with_stop_condition(method, block)
      catch :stop_condition_met do
        begin
          Watirmark::Session.instance.stop_condition_block = block
          send(method)
        ensure
          Watirmark::Session.instance.stop_condition_block = Proc.new {}
        end
        raise Watirmark::TestError, "Expected a stop condition but no stop conditon met!"
      end
    end

    def record_list
      @records << @model if records.empty?
      @records
    end

    def clear_record_list
      @records = []
    end

    def run_callback_method name
      send name if respond_to?(name)
    end

    def execute_actions(actions)
      actions.each do |action|
        run_callback_method :before_each
        send(action)
        run_callback_method :after_each
      end
    end

    def create_model(record)
      if record.kind_of?(Hash)
        @model = hash_to_model(record)
      else
        @model = record
      end
    end
  end
end