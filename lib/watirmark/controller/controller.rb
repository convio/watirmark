require 'watirmark/controller/actions'
require 'watirmark/controller/dialogs'
require 'watirmark/controller/assertions'

module Watirmark
  module WebPage

    class Controller
      attr_reader :model, :supermodel
      include Watirmark::Assertions
      include Watirmark::Dialogs
      include Watirmark::Actions

      class << self
        attr_accessor :view, :model, :search

        def inherited(klass)
          klass.view ||= @view if @view
          klass.model ||= @model if @model
          klass.search ||= @search if @search
        end
      end

      def initialize(data = {})
        @supermodel = data
        @model = locate_model @supermodel
        @records ||= []
        @view = self.class.view.new browser
        @search = self.class.search
      end

      def browser
        Page.browser
      end

      def model=(x)
        @model = (x.kind_of?(Hash) ? hash_to_model(x) : x)
      end

      def populate_data
        if populate_values
          if respond_to? submit_process_page_method
            submit_process_page
          else
            submit
          end
        end
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
              self.send(method)
            end
          end
          next unless @view.permissions[keyword.to_sym] and @view.permissions[keyword.to_sym][:populate]
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

      def verify_data
        verification_errors = []
        each_keyword do |keyword, process_page_name|
          next unless @view.permissions[keyword.to_sym] and @view.permissions[keyword.to_sym][:verify]
          value = value_for(keyword)
          next if value.nil?
          begin
            check(keyword, value)
          rescue Watirmark::VerificationException => e
            verification_errors.push e.to_s
          end
        end
        unless verification_errors.empty?
          raise Watirmark::VerificationException, verification_errors.join("\n  ")
        end
      end

      def submit_process_page_method
        "submit_process_page_#{last_process_page_name}"
      end

      def submit_process_page
        if @last_process_page
          if respond_to?(submit_process_page_method)
            send(submit_process_page_method)
          else
            @view[@last_process_page].submit
          end
        else
          @view[@view.to_s].submit
        end
      end

    private

      def locate_model(supermodel)
        case supermodel
          when Hash
            if self.class.model
              self.class.model.new supermodel
            else
              hash_to_model supermodel
            end
          else
            if self.class.model
              if supermodel.model_type == self.class.model
                supermodel
              else
                supermodel.find(self.class.model) || supermodel
              end
            else
              supermodel
            end
        end
      end

      # This is for legacy tests that still pass in a hash. We
      # convert these to models fo now
      def hash_to_model(hash)
        model = ModelOpenStruct.new
        hash.each_pair { |key, value| model.send "#{key}=", value }
        model
      end

      def each_keyword
        @view.process_pages.each { |page| process_page_keywords(page) { |x| yield x, page.name } }
      end

      def process_page_keywords(process_page)
        raise RuntimeError, "Process Page '#{page_name}' not found in #@view" unless process_page
        process_page.keywords.each { |x| yield x }
      end

      def view_keywords
        @view.keywords.each { |x| yield x }
      end

      def last_process_page_name
        @last_process_page.gsub(' ', '_').gsub('>', '').downcase
      end

      # Set a single keyword to it's corresponding value
      def set(keyword, value)
        # before hooks
        if self.respond_to?("before_#{keyword}")
          self.send("before_#{keyword}")
        elsif self.respond_to?("before_each_keyword")
          self.send("before_each_keyword", @view.send(keyword))
        end

        # populate
        if self.respond_to?("populate_#{keyword}")
          self.send("populate_#{keyword}")
        else
          @view.send "#{keyword}=", value
        end

        # after hooks
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

      # override this in your controller to define how a generic form submission should be done
      def submit
        warn "The #submit method needs to be defined in your controller to define you you submit a form"
      end
    end

  end
end
