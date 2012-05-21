require 'watirmark/controller/actions'
require 'watirmark/controller/dialogs'
require 'watirmark/controller/matcher'
require 'watirmark/controller/assertions'

module Watirmark
  module WebPage
    
=begin rdoc
class MyController < Watirmark::WebPage::Controller
  include ECRMPage               # include any default methods (this will include model and WebPage methods)
  @view = MyView                 # This is required and should point to a view. Navigation also should be in the view
  
  # In the simplest case, that's ALL you need. Most of the 
  # real info should be contained in your View. Below are some 
  # tools you can use to override default behavior

  # Override getting the keywords from the view and just use these keywords. 
  # This is useful if there's a quickcreate or some path where the edit and 
  # create screens are different
  keyword :keyword1, :keyword2, ...

  # When running the populate/verify methods, ignore these
  # keywords. Note that buttons and links won't get called
  # so you don't need to add them here, as they will just get ignored

  reject :keyword1, :keyword2, ...    

  # Override how the controller populates.
  def populate_data
    super # to call the default populate
    # do something
  end
  
  # Override how the controller verifies.
  def verify_data
    super # to call the default verify
    # do something
  end

  # Change the model value for a keyword. Note that this
  # will both set the value using this and will verify 
  # as if this is the model value so you shouldn't have to
  # override the verification unless they differ
  #
  # def #{keyword}_value; # do something; end

  def currency_value
    "$#{@model.currency}"
  end

  # Override verification for a given element.
  # In this example the file_field that sets the value is blank
  # when we verify so we just check that an image was uploaded 
  # by looking at what buttons appear 
  #
  # def verify_#{keyword}; # do something; end

  def verify_image
    if @view.uploadimage.exists?
      assert @model.image == 'nil'
    elsif @view.uploaddifferentimage.exists?
      assert @model.image != 'nil'
    end
  end


  # Override data population for a given element.
  # In this case we have a model value that maps
  # to a keyword that has no proc and we override
  # things here 
  #
  # def populate_#{keyword}; # do something; end

  def populate_teamdivisions
    @model.teamdivisions.each do |team|
      @view.teamdivision.set team
      close_dialog_if_exists { @view.adddivbutton.click_no_wait }
      Watir::Waiter.wait_until do
        @view.divisionname(team).exists?
      end
    end
  end

  # Add behavior before an element is set (populate only)
  #
  # def before_#{keyword}; # do something; end

  def before_image
    @view.image.fire_event('OnChange')
  end

  # Add behavior after an element is set (populate only)
  #
  # def after_#{keyword}; # do something; end

  def after_image
    @view.upload_button.click
  end
  
  # Override the default submit behavior which is 
  # to click a Save/Next/Finish button. 
  def submit
    @view.completebutton.click
  end

  # Override the default submit behavior for a process page
  def process_page_[some_page_name]
    @view.completebutton.click
  end

  # Add behaviour before a process page is executed
  def before_process_page_[some_page_name]
    @view.somelink.click
  end

  ### METHODS FROM Watirmark::WebPage ###

  def create; end                  # navigates to the create page and runs populate_data
  def edit; end                    # navigates to the edit page and runs populate_data
  def verify; end                  # navigates to the edit page and runs verify_data
  def check_create_defaults; end   # navigates to the create page and runs verify_data

  ANY other methods should be created in the controller and delegated to the View:
 
  def delete; @view.delete; end 
  def archive; @view.archive; end
  ...etc... 

  # These methods will be called if defined.
  def before_all; end              # runs before any record is read.
  def before_each; end             # runs before each record (row/col)
  def after_each; end              # runs after each record (row/col)
  def after_all; end               # runs after all records processed

end
=end rdoc

    class Controller
      attr_reader :model, :model
      include Watirmark::Assertions
      include Watirmark::Dialogs
      include Watirmark::Actions
      
      class << self
        attr_accessor :view, :process_page, :specified_keywords

        def inherited(klass) #:nodoc:
          klass.view ||= @view if @view 
        end
        
        # For custom Keyword classes we want to filter out
        # any keywords that are automatically generated so 
        # we don't get or set them twice. This builds a list
        # of keywords to remove from the auto-generated lists.

        def stub (method_name)
          define_method  method_name.to_sym do;end
        end

        def reject(*items)
          items.each { |item| stub "populate_#{item}"; stub "verify_#{item}";}
        end
        
        def verify_only(*items)
          items.each { |item| stub "populate_#{item}"}
        end

        def populate_only(*items)
          items.each { |item| stub "verify_#{item}"}
        end

        def keyword(x)
         (@specified_keywords ||= []) << x 
        end
        
        def keywords(items)
          items.each { |item| self.keyword(item) }
        end
        
        # Populate with model values
        def populate(x) 
          new(x).populate
          return
        end
        
        # Verify the UI values and compare with the model values
        def verify(x) 
          new(x)._verify_
          return
        end
      end
      
      def initialize(data = {}) #:nodoc:
        @records ||= []
        @view = self.class.view
        @process_page = self.class.process_page
        @specified_keywords = self.class.specified_keywords
        if Hash === data # convert to a model
          @model = hash_to_model data
        else
          @model = data
        end
        # Create a session if one does not exist
        @session = Watirmark::IESession.instance
        @browser = @session.openbrowser
      end

      def hash_to_model(hash)
        model = ModelOpenStruct.new
        hash.each_pair { |key, value| model.send "#{key}=", value }
        model
      end

      def model=(x)
        if Hash === x
          @model = hash_to_model(x)
        else
          @model = x
        end
      end

      def each_keyword #:nodoc:
        # user has overridden keywords so don't automatically get anything else
        if @specified_keywords 
          @specified_keywords.each {|x| yield x, nil}
    # This should probably go away if we can work out how to 
    # handle TR process pages in what is required and not
        elsif @process_page
          process_page_keywords(@view[@process_page]) {|x| yield x, @process_page}
        elsif @view.process_pages
          @view.process_pages.each { |page| process_page_keywords(page) {|x| yield x, page.name} }
        else
          raise Watirmark::TestError, 'View or Process Page not defined in controller!'
        end
      end
      
      # Returns all of the keywords associated with a process page
      def process_page_keywords(process_page)
        raise RuntimeError, "Process Page '#{page_name}' not found in #{@view}" unless process_page
        process_page.keywords.each {|x| yield x}
      end
      
      # Returns all the keywords in the view
      def view_keywords
        @view.keywords.each {|x| yield x}
      end

      def last_process_page_name
        @last_process_page.gsub(' ','_').gsub('>','').downcase
      end

      # This action will populate all of the items
      # in the view with values in @model
      def populate 
        seen_value = false
        @last_process_page = nil
        each_keyword do |keyword, process_page|
          if @last_process_page != process_page
            if seen_value && @view[process_page].page_name !~ /::/     #hack so we handle inherited kwds without submits
              _submit_
              seen_value = false
            end
            @last_process_page = process_page
            if self.respond_to?(method = "before_process_page_#{last_process_page_name}"); self.send(method); end
          end
          value = value_for(keyword)
          value.nil? ? next : seen_value = true
          set(keyword, value)
        end
        _submit_ if seen_value
      end
      alias :populate_data :populate
      
      # This action will verify all values in the
      # view against @model without page submission
      def _verify_ #:nodoc:
        verification_errors = []
        each_keyword do |keyword, process_page_name|
          value = value_for(keyword)
          next if value.nil?
          begin
            check(keyword, value)
          rescue Watirmark::VerificationException => e
            verification_errors.push e.to_s
          rescue Exception => e #FIXME: this clause may be TMI
            raise e, e.to_s+" and validation errors\n  "+(verification_errors.join "\n  ") if verification_errors.size>0
            raise e
          end
        end
        if verification_errors.size == 1
          raise Watirmark::VerificationException, verification_errors[0]
        elsif verification_errors.size > 1
          raise Watirmark::VerificationException, "Multiple problems -\n  "+(verification_errors.join "\n  ")
        end
      end
      alias :verify_data :_verify_
      
      # Check before submitting to see if the process page
      # submit override is being used, then submit and allow the controller
      # to override the submit method if necessary
      def _submit_
        method = nil
        method =  "submit_process_page_#{last_process_page_name}" if @last_process_page
        if method && self.respond_to?(method)
          self.send(method)
        else
          submit
        end
      end

      # Action to take at the end of a process page or single page.
      # This is a user-defined proc in the process page that can be
      # different for each platform and overridden in any given view
      def submit
        @view[@last_process_page || @view.to_s].submit
      end
      
      # Set a single keyword to it's corresponding value
      def set(keyword, value)
        #before hooks
        if self.respond_to?("before_#{keyword}")
          self.send("before_#{keyword}")
        elsif self.respond_to?("before_each_keyword")
          self.send("before_each_keyword",@view.send(keyword))
        end

        #populate
        if self.respond_to?("populate_#{keyword}")
          self.send("populate_#{keyword}")
        else
          @view.send "#{keyword}=", value
        end

        #after hooks
        if self.respond_to?("after_#{keyword}")
          self.send("after_#{keyword}")
        elsif self.respond_to?("after_each_keyword");
          self.send("after_each_keyword",@view.send(keyword))
        end
      end
      
      # Verify the value from a keyword matches the given value
      def check(keyword, value)
        if self.respond_to?(method = "verify_#{keyword}")
          self.send(method)
        else
          actual_value = @view.send(keyword)
          case actual_value
            when Array
            # If the value retrieved is an array convert the value ot an array so single strings match too
            assert_equal actual_value, value.to_a
          else
            assert_equal actual_value, value
          end
        end
      end

      # if a method exists that changes how the value of the keyword
      # is determined then call it, otherwise, just use the model value
      def value_for(keyword)
        self.respond_to?(method = "#{keyword}_value") ? self.send(method) : @model.send(keyword)
      end
      
    end

    def log
      Watirmark::Configuration.instance.logger
    end

  end
end