require 'watirmark/page/page_definition'

module Watirmark
  class Page
    extend PageDefinition

    attr_accessor :browser
    attr_reader   :keyed_elements

    def initialize(browser=self.class.browser)
      @browser = browser
      @keyed_elements = []
      create_keyword_methods
    end

    def keywords
      self.class.keywords
    end

    def native_keywords
      self.class.native_keywords
    end

    def process_pages
      self.class.process_pages
    end

    def process_page(x)
      process_pages.each { |page| return page if page.name == x }
      raise RuntimeError, "Process Page '#{x}' not found in #{self}"
    end

  private

    def create_keyword_methods
      keywords = self.class.keyword_metadata || {}
      keywords.each_key do |key|
        keyed_element = KeyedElement.new(self, keywords[key])
        @keyed_elements << keyed_element
        meta_def key do |*args|
          keyed_element.get *args
        end
        meta_def "#{key}=" do |*args|
          keyed_element.set *args
        end
      end
    end
  end
end

Page = Watirmark::Page