require 'watirmark/page/process_page'

module Watirmark

  class Page

    class << self
      @@browser = nil
      attr_accessor :keywords, :process_pages, :kwds, :perms , :keyword_metadata, :keyword_aliases
      attr_accessor :process_page_navigate_method, :process_page_submit_method,
                    :process_page_submit_method, :process_page_active_page_method

      # When a view inherits another view, we want the subclass
      # to report the keywords and process pages pulling in all
      # subclasses. That way you can use the :keywords to see *all*
      # the available keywords and not just the ones explicitly defined
      # in that view.
      #
      # Also we want to create a default process page even if there is not
      # a process page in use. This allows us to handle each view the same way
      # and not have to see if it's using process pages or not.
      def inherited(klass)
        add_superclass_keywords(klass)
        add_superclass_permissions(klass)
        add_superclass_process_pages(klass)
        create_default_process_page(klass)
      end

      def keywords
        @kwds.values.flatten.uniq.sort_by { |key| key.to_s }
      end

      def native_keywords
        @kwds[self].sort_by { |key| key.to_s }
      end

      def keyword(name, map=nil, &block)
        create_new_keyword(name, map, permissions={:populate => true, :verify => true}, &block)
      end

      def populate_keyword(name, map=nil, &block)
        create_new_keyword(name, map, permissions={:populate => true}, &block)
      end

      def verify_keyword(name, map=nil, &block)
        create_new_keyword(name, map, permissions={:verify => true}, &block)
      end

      def private_keyword(name, map=nil, &block)
        create_new_keyword(name, map, &block)
      end
      alias :navigation_keyword :private_keyword

      # Create an alias to an existing keyword
      def keyword_alias(keyword_alias_name, keyword_name)
        @keyword_aliases ||= Hash.new{|h,k| h[k] = Array.new}
        @keyword_aliases[keyword_name] << keyword_alias_name
      end

      def process_page(name, method=nil)
        @current_process_page = find_or_create_process_page(name)
        @current_process_page.navigate_method = @process_page_navigate_method
        @current_process_page.submit_method = @process_page_submit_method
        @current_process_page.active_page_method = @process_page_active_page_method
        yield
        @current_process_page = @current_process_page.parent
      end

      def process_page_alias(x)
        @current_process_page.alias << x
      end

      def always_activate_parent
        @current_process_page.always_activate_parent = @current_process_page.parent.page_name
      end

      def browser
        @@browser ||= Watirmark::Session.instance.openbrowser
      end

      def browser=(x)
        @@browser = x
      end

    private

      def create_new_keyword(name, map=nil, permissions, &block)
        add_to_keywords(name)
        add_permission(name, permissions)
        @current_process_page << name if permissions
        @keyword_metadata ||= Hash.new{|h,k| h[k]=Hash.new}
        @keyword_metadata[name][:key] = name
        @keyword_metadata[name][:map] = map
        @keyword_metadata[name][:permissions] = permissions
        @keyword_metadata[name][:block] = block
        @keyword_metadata[name][:process_page] = @current_process_page
      end

      def add_permission(kwd, hash)
        @perms ||= Hash.new { |h, k| h[k] = Hash.new }
        @perms[self][kwd] = hash
      end

      def add_to_keywords(method_sym)
        @kwds ||= Hash.new { |h, k| h[k] = Array.new }
        @kwds[self] << method_sym unless @kwds.include?(method_sym)
      end

      def add_superclass_keywords(klass)
        if @kwds
          klass.kwds ||= Hash.new { |h, k| h[k] = Array.new }
          @kwds.each_key do |k|
            klass.kwds[k] = @kwds[k].dup
          end
        end
      end

      def add_superclass_process_pages(klass)
        klass.process_pages = (@process_pages ? @process_pages.dup : klass.process_pages = [])
      end

      def add_superclass_permissions(klass)
        if @perms
          klass.perms ||= Hash.new { |h, k| h[k] = Hash.new }
          @perms.each_key do |k|
            klass.perms[k] = @perms[k].dup
          end
        end
      end

      def create_default_process_page(klass)
        klass.instance_variable_set :@current_process_page, ProcessPage.new(klass.inspect)
        current_page = klass.instance_variable_get(:@current_process_page)
        current_page.root = true
        klass.process_pages << current_page
      end

      def find_or_create_process_page(name)
        mypage = find_process_page(name)
        unless mypage
          mypage = ProcessPage.new(name, @current_process_page)
          @process_pages ||= []
          @process_pages << mypage
        end
        mypage
      end

      def find_process_page(name)
        name = @current_process_page.name + ' > ' + name unless @current_process_page.root
        @process_pages.find { |p| p.name == name }
      end

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
