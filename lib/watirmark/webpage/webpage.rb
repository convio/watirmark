require 'watirmark'
require 'watirmark/webpage/page'
require 'watirmark/webpage/dialogs'
require 'watirmark/webpage/assertions'
require 'watirmark/webpage/extensions'
require 'watirmark/webpage/controller'
require 'american_date'

module Watirmark

  # This module defines all of the methods we'd like
  # to have available for all controllers. 
  #
  # class MyFeature << Watirmark::WebPage::Controller
  #   include WebPage
  #   ...
  # end
  #
  # Generally, however, your application will have some 
  # more specific methods you'll want to include so you 
  # would probably include WebPage into that class and use
  # it as a default class for the application (aka ECRMPage)
  #
  # Also note that in addition, we're importing Rasta
  # methods and the main ones that can be defined in 
  # your controller are:
  #
  #   before_all: callback called before any records on a worksheet tab are processed
  #   before_each: callback called before any records (row or column) are processed
  #   after_each: callback called after any records (row or column) are processed
  #   after_all: callback called after all records on a worksheet tab are processed
  
  module WebPage 
    include Assertions
    include Dialogs    

    attr_accessor :records, :rasta
    
    # Create a new browser session if one does not exist
    # and initialize the rasta hash
    def initialize(*args)
      @rasta ||= {}
      @records = []
      # this normally would call the initialize on the controller
      # but it fails in CG where there are classes not subclassed from
      # ConvioWebPage or Controller.
      super unless self.class.superclass == Object
      @session = Watirmark::IESession.instance
      @browser = @session.openbrowser
    end

    def log
      Watirmark::Configuration.instance.logger
    end

    def run(*args)
      begin
        @records << @rasta if @records.size == 0
        before_all if respond_to?(:before_all)
        @records.each do |record|
          self.rasta = record
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

    def update_model
      @model.update(@rasta) if @model
    end

    # Navigate to the View's edit page and for every value in 
    # the Rasta hash, verify that the html element has
    # the proper value for each keyword
    def verify
      call_view_method(:edit, @rasta)
      verify_data
      update_model
    end
   
    # Navigate to the View's edit page and  
    # verify all values in the Rasta hash
    def edit
      call_view_method(:edit, @rasta)
      populate_data
      update_model
    end
    
    # Navigate to the View's create page and 
    # populate with values from the Rasta hash
    def create
      call_view_method(:create, @rasta)
      populate_data
      update_model
    end
    
    # Navigate to the View's create page and
    # populate with values from the Rasta hash
    def get
      unless call_view_method(:exists?, @rasta)
        call_view_method(:create, @rasta)
        populate_data
      end
      update_model
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

