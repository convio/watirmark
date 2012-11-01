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
        if populate_values
          submit_process_page_override(@last_process_page) || submit
        end
      end

      def populate_values
        seen_value = false
        @last_process_page = nil
        keyed_elements_with_values.each do |keyed_element|
          next unless keyed_element.populate_allowed?
          keyword = keyed_element.keyword
          process_page = keyed_element.process_page.name

          if @last_process_page != process_page
            if seen_value
              if @last_process_page
                submit_process_page_override(@last_process_page) || @view.process_page(@last_process_page).submit
              else
                @view.process_page(@view.to_s).submit
              end
              seen_value = false
            end
            @last_process_page = process_page
            before_process_page_override(@last_process_page)
          end

          begin
            seen_value = true
            before_keyword_override(keyword)
            populate_keyword_override(keyword) || @view.send("#{keyword}=", value(keyed_element))
            after_keyword_override(keyword)
          rescue => e
            puts "Got #{e.class} when attempting to populate '#{keyed_element.keyword}'"
            raise e
          end
        end
        seen_value
      end

      def verify_data
        verification_errors = []
        keyed_elements_with_values.each do |keyed_element|
          next unless keyed_element.verify_allowed?
          begin
            verify_keyword_override(keyed_element.keyword) || assert_equal(keyed_element.get, value(keyed_element))
          rescue Watirmark::VerificationException => e
            verification_errors.push e.to_s
          end
        end
        unless verification_errors.empty?
          raise Watirmark::VerificationException, verification_errors.join("\n  ")
        end
      end


    private

      def call_method(method)
        send(method) if respond_to?(method)
      end

      def before_keyword_override(keyword)
        call_method "before_#{keyword}"
      end

      def after_keyword_override(keyword)
        call_method "after_#{keyword}"
      end

      def populate_keyword_override(keyword)
        call_method "populate_#{keyword}"
      end

      def verify_keyword_override(keyword)
        call_method "verify_#{keyword}"
      end

      def keyword_value_override(keyed_element)
        call_method "#{keyed_element.keyword}_value"
      end

      def before_process_page_override(name)
        call_method "before_process_page_#{name}"
      end

      def submit_process_page_override(name)
        call_method "submit_process_page_#{name}"
      end

      def value(keyed_element)
        @cache ||= {}
        @cache[keyed_element] ||= (keyword_value_override(keyed_element) || @model.send(keyed_element.keyword))
      end

      def keyed_elements_with_values
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


      # override this in your controller to define how a generic form submission should be done
      def submit
        warn "The #submit method needs to be defined in your controller to define you you submit a form"
      end
    end

  end
end
