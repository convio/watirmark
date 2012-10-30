require 'watirmark/page/page_definition'

module Watirmark
  class Page

    class << self
      include PageDefinition
    end

    attr_accessor :browser

    def initialize(browser=nil)
      @browser = browser || self.class.browser
      create_keyword_methods
      create_keyword_aliases
    end

    def create_keyword_methods
      keywords = self.class.keyword_metadata || {}
      keywords.each_key do |key|
        keywords[key][:page] = self
        keyed_element = KeyedElement.new keywords[key]
        meta_def key do |*args|
          keyed_element.get *args
        end
        meta_def "#{key}=" do |*args|
          keyed_element.set *args
        end
      end
    end

    def create_keyword_aliases
      aliases = self.class.keyword_aliases
      return unless aliases
      aliases.each_key do |name|
        aliases[name].each do |an_alias|
          instance_eval "alias #{an_alias} #{name}"
        end
      end
    end

    def keywords
      self.class.keywords
    end

    def native_keywords
      self.class.native_keywords
    end

    def permissions
      self.class.permissions
    end

    def process_pages
      self.class.process_pages
    end

    def process_page(x)
      process_pages.each { |page| return page if page.name == x }
      raise RuntimeError, "Process Page '#{x}' not found in #{self}"
    end
  end
end

Page = Watirmark::Page