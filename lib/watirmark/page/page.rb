require 'watirmark/page/page_definition'
require 'watirmark/page/process_page'

module Watirmark

  class Page

    class << self
      include PageDefinition
    end

    attr_accessor :keywords, :process_pages, :browser

    def initialize(browser=nil)
      @browser = browser || self.class.browser
      @keywords = self.class.keywords
      @process_pages = self.class.process_pages
      @kwds = self.class.kwds
      @perms = self.class.perms
      create_keyword_methods
      create_keyword_aliases
    end

    def create_keyword_methods
      keywords = self.class.keyword_metadata
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
          warn("Warning: Deprecated use of `keyword_alias` to access "\
              "`#{aliases[name]}` with `#{an_alias}`in #{self}.")
          instance_eval "alias #{an_alias} #{name}"
        end
      end
    end

    def process_page(x)
      @process_pages.each { |page| return page if page.name == x }
      raise RuntimeError, "Process Page '#{x}' not found in #{self}"
    end

    def permissions
      @perms ||= Hash.new { |h, k| h[k] = Hash.new }
      @perms.values.inject(:merge)
    end
  end
end


# Make this class a little easier to get to
Page = Watirmark::Page
