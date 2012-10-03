require 'watirmark/controller/actions'
require 'watirmark/controller/dialogs'
require 'watirmark/controller/matcher'
require 'watirmark/controller/assertions'

module Watirmark
  module WebPage

    class Controller
      attr_reader :model, :supermodel
      include Watirmark::Assertions
      include Watirmark::Dialogs
      include Watirmark::Actions

      class << self
        attr_accessor :view, :model, :search, :process_page

        def inherited(klass) #:nodoc:
          klass.view ||= @view if @view
          klass.model ||= @model if @model
          klass.search ||= @search if @search
        end
      end

      def initialize(data = {}) #:nodoc:
        @supermodel = data
        @records ||= []
        @view = self.class.view
        @search = self.class.search
        @process_page = self.class.process_page
        case @supermodel
          when Hash
            if self.class.model
              @model = self.class.model.new
            else
              @model = hash_to_model @supermodel
            end
            @supermodel = @model
          else
            if self.class.model
              @model = @supermodel.find(self.class.model) || @supermodel
            else
              @model = @supermodel
            end
        end
        # Create a session if one does not exist
        @session = Watirmark::Session.instance
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
        if @process_page
          process_page_keywords(@view[@process_page]) { |x| yield x, @process_page }
        elsif @view.process_pages
          @view.process_pages.each { |page| process_page_keywords(page) { |x| yield x, page.name } }
        else
          raise Watirmark::TestError, 'View or Process Page not defined in controller!'
        end
      end

      # Returns all of the keywords associated with a process page
      def process_page_keywords(process_page)
        raise RuntimeError, "Process Page '#{page_name}' not found in #{@view}" unless process_page
        process_page.keywords.each { |x| yield x }
      end

      # Returns all the keywords in the view
      def view_keywords
        @view.keywords.each { |x| yield x }
      end

      def last_process_page_name
        @last_process_page.gsub(' ', '_').gsub('>', '').downcase
      end

      # This action will populate all of the items
      # in the view with values in @model
      def populate_data
        submit_process_page if populate_values
      end

      def populate_values
        seen_value = false
        @last_process_page = nil
        each_keyword do |keyword, process_page|
          if @last_process_page != process_page
            if seen_value && @view[process_page].page_name !~ /::/ #hack so we handle inherited kwds without submits
              submit_process_page
              seen_value = false
            end
            @last_process_page = process_page
            if self.respond_to?(method = "before_process_page_#{last_process_page_name}");
              self.send(method);
            end
          end
          unless @view.permissions[keyword.to_sym] and @view.permissions[keyword.to_sym][:populate]
            next
          end
          begin
            value = value_for(keyword)
            value.nil? ? next : seen_value = true
            set(keyword, value)
          rescue => e
            puts "Got #{e.class} when attempting to populate '#{keyword}' on page '#{process_page}'"
            raise e
          end
        end
        seen_value
      end

      # This action will verify all values in the
      # view against @model without page submission
      def verify_data
        verification_errors = []
        each_keyword do |keyword, process_page_name|
          unless @view.permissions[keyword.to_sym] and @view.permissions[keyword.to_sym][:verify]
            next
          end
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

      # Check before submitting to see if the process page
      # submit override is being used, then submit and allow the controller
      # to override the submit method if necessary
      def submit_process_page
        method = nil
        method = "submit_process_page_#{last_process_page_name}" if @last_process_page
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
          self.send("before_each_keyword", @view.send(keyword))
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
          self.send("after_each_keyword", @view.send(keyword))
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

  end
end
