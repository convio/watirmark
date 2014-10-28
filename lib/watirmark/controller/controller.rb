require 'watirmark/controller/actions'
require 'watirmark/controller/dialogs'
require 'watirmark/controller/assertions'
require 'watirmark/controller/matcher'
require 'wait'

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
        initialize_model(data)
        @records ||= []
        @cache = {}
        @view = self.class.view.new browser if self.class.view
        @search = self.class.search
      end

      def browser
        Page.browser
      end

      def model=(data)
        initialize_model(data)
      end

      def populate_data
        submit_process_page(@last_process_page.underscored_name) {submit} if populate_values
      end

      def populate_values
        @seen_value = false
        @last_process_page = nil
        keyed_elements.each do |k|
          next unless k.populate_allowed?
          submit_process_page_when_page_changes(k)
          before_process_page(k)
          populate_keyword(k)
        end
        @seen_value
      end

      def verify_data
        @verification_errors = []
        keyed_elements.each { |k| verify_keyword(k) if k.verify_allowed? }
        raise Watirmark::VerificationException, @verification_errors.join("\n  ") unless @verification_errors.empty?
      end

    private

      def initialize_model(x)
        @supermodel = x
        @model = locate_model @supermodel
      end

      def populate_keyword(keyed_element)
        begin
          before_keyword(keyed_element)
          populate_keyword_value(keyed_element)
          after_keyword(keyed_element)
          @seen_value = true
        rescue => e
          Watirmark.logger.warn "Unable to populate '#{keyed_element.keyword}'"
          raise e
        end
      end

      def verify_keyword(keyed_element)
        begin
          verify_keyword_value(keyed_element)
        rescue Watirmark::VerificationException => e
          @verification_errors.push e.to_s
        end
      end

      def submit_process_page_when_page_changes(keyed_element)
        return unless process_page_changed?(keyed_element) && @seen_value
        if @last_process_page
          submit_process_page(@last_process_page.underscored_name) {@view.process_page(@last_process_page.name).submit}
        else
          @view.process_page(@view.to_s).submit
        end
        @seen_value = false
      end

      def call_method_if_exists(override)
        if respond_to?(override)
          send(override)
        else
          yield if block_given?
        end
      end

      def process_page_defined?(keyed_element)
        !keyed_element.process_page.underscored_name.empty?
      end

      def process_page_changed?(keyed_element)
        !!(@last_process_page && @last_process_page.underscored_name != keyed_element.process_page.underscored_name)
      end

      def before_keyword(keyed_element)
        call_method_if_exists("before_#{keyed_element.keyword}")
      end

      def after_keyword(keyed_element)
        call_method_if_exists("after_#{keyed_element.keyword}")
      end

      def populate_keyword_value(keyed_element)
        call_method_if_exists("populate_#{keyed_element.keyword}") do
          # for the first element on a page we populate, wait for it to appear
          @view.send(keyed_element.keyword).send(:wait_until_present) unless @seen_value
          @view.send("#{keyed_element.keyword}=", value(keyed_element))
        end
      end

      def verify_keyword_value(keyed_element)
        call_method_if_exists("verify_#{keyed_element.keyword}") {assert_equal(keyed_element.get, value(keyed_element))}
      end

      def keyword_value(keyed_element)
        call_method_if_exists("#{keyed_element.keyword}_value") {@model.send(keyed_element.keyword)}
      end

      def before_process_page(keyed_element)
        if process_page_defined?(keyed_element) && (@last_process_page.nil? || process_page_changed?(keyed_element))
          call_method_if_exists("before_process_page_#{keyed_element.process_page.underscored_name}")
        end
        @last_process_page = keyed_element.process_page
      end

      def submit_process_page(name, &block)
        call_method_if_exists("submit_process_page_#{name}", &block)
      end

      def value(keyed_element)
        @cache[keyed_element] ||= keyword_value(keyed_element)
      end

      def keyed_elements
        @cache = {}
        @view.keyed_elements.select{|e| !value(e).nil?}
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
        Watirmark.logger.warn "Unable to automatically post form. Please defined a submit method in your controller"
      end
    end

  end
end
