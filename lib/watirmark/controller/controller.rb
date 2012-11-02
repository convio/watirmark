require 'watirmark/controller/actions'
require 'watirmark/controller/dialogs'
require 'watirmark/controller/assertions'
require 'watirmark/controller/matcher'

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
        @view = self.class.view.new browser if self.class.view
        @search = self.class.search
      end

      def browser
        Page.browser
      end

      def model=(x)
        @model = (x.kind_of?(Hash) ? hash_to_model(x) : x)
      end

      def populate_data
        (submit_process_page_override(@last_process_page.underscored_name) || submit) if populate_values
      end

      def populate_values
        @seen_value = false
        @last_process_page = nil
        keyed_elements.each { |k| populate_keyword(k) }
        @seen_value
      end

      def verify_data
        @verification_errors = []
        keyed_elements.each { |k| verify_keyword(k) }
        raise Watirmark::VerificationException, @verification_errors.join("\n  ") unless @verification_errors.empty?
      end

    private

      def populate_keyword(keyed_element)
        return unless keyed_element.populate_allowed?
        submit_process_page_when_page_changes(keyed_element.process_page)
        begin
          @seen_value = true
          before_keyword_override(keyed_element.keyword)
          populate_keyword_override(keyed_element.keyword) || @view.send("#{keyed_element.keyword}=", value(keyed_element))
          after_keyword_override(keyed_element.keyword)
        rescue => e
          puts "Unable to populate '#{keyed_element.keyword}'"
          raise e
        end
      end

      def verify_keyword(keyed_element)
        return unless keyed_element.verify_allowed?
        begin
          verify_keyword_override(keyed_element.keyword) || assert_equal(keyed_element.get, value(keyed_element))
        rescue Watirmark::VerificationException => e
          @verification_errors.push e.to_s
        end
      end

      def submit_process_page_when_page_changes(process_page)
        if @last_process_page != process_page
          if @seen_value
            if @last_process_page
              submit_process_page_override(@last_process_page.underscored_name) || @view.process_page(@last_process_page.name).submit
            else
              @view.process_page(@view.to_s).submit
            end
            @seen_value = false
          end
          @last_process_page = process_page
          before_process_page_override(@last_process_page.underscored_name)
        end
      end

      def call_method_if_exists(method)
        if respond_to?(method)
          send(method) || true
        else
          false
        end
      end

      def before_keyword_override(keyword)
        call_method_if_exists "before_#{keyword}"
      end

      def after_keyword_override(keyword)
        call_method_if_exists "after_#{keyword}"
      end

      def populate_keyword_override(keyword)
        call_method_if_exists "populate_#{keyword}"
      end

      def verify_keyword_override(keyword)
        call_method_if_exists "verify_#{keyword}"
      end

      def keyword_value_override(keyed_element)
        call_method_if_exists "#{keyed_element.keyword}_value"
      end

      def before_process_page_override(name)
        call_method_if_exists "before_process_page_#{name}" if name
      end

      def submit_process_page_override(name)
        call_method_if_exists "submit_process_page_#{name}" if name
      end

      def value(keyed_element)
        @cache ||= {}
        @cache[keyed_element] ||= (keyword_value_override(keyed_element) || @model.send(keyed_element.keyword))
      end

      def keyed_elements
        @view.keyed_elements.select{|e| value(e)}
      end

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

      def submit
        warn "Unable to automatically post form. Please defined a submit method in your controller"
      end
    end

  end
end
