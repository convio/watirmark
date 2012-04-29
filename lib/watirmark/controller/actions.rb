module Watirmark
  module Actions

    attr_accessor :records

    def run(*args)
      begin
        @records << @rasta if @records.size == 0
        before_all if respond_to?(:before_all)
        @records.each do |record|
          @rasta = hash_to_model(record) if Hash === record
          args.each do |method|
            before_each if respond_to?(:before_each)
            self.send(method)
            after_each if respond_to?(:after_each)
          end
        end
        after_all if respond_to?(:after_all)
      ensure
        @records = []
      end
    end

    # Navigate to the View's edit page and for every value in
    # the Rasta hash, verify that the html element has
    # the proper value for each keyword
    def verify
      call_view_method(:edit, @rasta)
      verify_data
    end

    # Navigate to the View's edit page and
    # verify all values in the Rasta hash
    def edit
      call_view_method(:edit, @rasta)
      populate_data
    end

    # Navigate to the View's create page and
    # populate with values from the Rasta hash
    def create
      call_view_method(:create, @rasta)
      populate_data
    end

    # Navigate to the View's create page and
    # populate with values from the Rasta hash
    def get
      unless call_view_method(:exists?, @rasta)
        call_view_method(:create, @rasta)
        populate_data
      end
    end

    # delegate to the view to delete
    def delete
      call_view_method(:delete, @rasta)
    end

    # delegate to the view to copy
    def copy
      call_view_method(:copy, @rasta)
    end

    # delegate to the view to restore
    def restore
      call_view_method(:restore, @rasta)
    end

    # delegate to the view to archive
    def archive
      call_view_method(:archive, @rasta)
    end

    # delegate to the view to activate
    def activate
      call_view_method(:activate, @rasta)
    end

    # delegate to the view to deactivate
    def deactivate
      call_view_method(:deactivate, @rasta)
    end

    def locate_record
      call_view_method(:locate_record, @rasta)
    end

    # Navigate to the View's create page and verify
    # against the Rasta hash. This is useful for making
    # sure that the create page has the proper default
    # values and contains the proper elements
    def check_defaults
      call_view_method(:create, @rasta)
      verify_data
    end
    alias :check_create_defaults :check_defaults


    def call_view_method(method_name, rasta_values) #:nodoc:
      view = self.class.view
      if view
        if view.respond_to?(method_name)
          view.send method_name, rasta_values
        else
          raise Watirmark::TestError, "Method #{method_name} undefined in #{@view}"
        end
      else
        log.info "No view defined for controller: #{self}"
      end
    end

    # A helper function for translating a string into a
    # pattern match for the beginning of a string
    def starts_with(x)
      /^#{Regexp.escape(x)}/
    end

    # Return all of the text in a browser. :TODO: remove
    def verify_contains_text
      @browser.text
    end

    # Stubs so converted XLS->RSPEC files don't fail
    def before_all; end
    def before_each; end
    def after_all; end
    def after_each; end
  end
end