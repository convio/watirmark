require 'watirmark/page/process_page'

module Watirmark
  module ProcessPageDefinition
    attr_accessor :process_pages,
                  :process_page_navigate_method,
                  :process_page_active_page_method,
                  :process_page_submit_method

    def process_page(name, method=nil)
      @current_process_page = find_or_create_process_page(name)
      yield
      @current_process_page = @current_process_page.parent
    end

    def process_page_alias(x)
      @current_process_page.alias << x
    end

    def always_activate_parent
      @current_process_page.always_activate_parent = @current_process_page.parent.name
    end

    def process_page_navigate_method(proc=nil)
      @process_page_navigate_method = proc
    end

    def process_page_submit_method(proc)
      @process_page_submit_method = proc
    end

    def process_page_active_page_method(proc)
      @process_page_active_page_method = proc
    end

  private

    def add_superclass_process_pages_to_subclass(klass)
      klass.process_pages = (@process_pages ? @process_pages.dup : klass.process_pages = [])
    end


    def create_default_process_page(klass)
      klass.instance_variable_set :@current_process_page, ProcessPage.new
      current_page = klass.instance_variable_get(:@current_process_page)
      current_page.root = true
      klass.process_pages << current_page
    end

    def find_or_create_process_page(name)
      mypage = find_process_page(name)
      unless mypage
        mypage = ProcessPage.new(name,
                                 @current_process_page,
                                 @process_page_active_page_method,
                                 @process_page_navigate_method,
                                 @process_page_submit_method
        )
        @process_pages ||= []
        @process_pages << mypage
      end
      mypage
    end

    def find_process_page(name)
      if @current_process_page.root
        underscored_name = name
      else
        underscored_name = (@current_process_page.underscored_name + '_' + name).downcase.gsub!(/\s+/, '_')
      end
      @process_pages.find { |p| p.underscored_name == underscored_name }
    end
  end



  module PageDefinition
    include ProcessPageDefinition
    attr_accessor :kwds, :perms, :kwd_metadata

    @@browser = nil

    def inherited(klass)
      add_superclass_keywords_to_subclass(klass)
      add_superclass_keyword_metadata_to_subclass(klass)
      add_superclass_process_pages_to_subclass(klass)
      create_default_process_page(klass)
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
      keyword_data = @kwd_metadata[self.to_s][keyword_name]
      create_new_keyword(keyword_alias_name, keyword_data[:map], keyword_data[:permissions], &keyword_data[:block])
    end

    def browser
      @@browser ||= Watirmark::Session.instance.openbrowser
    end

    def browser=(x)
      @@browser = x
    end

    def browser_exists?
      !! @@browser
    end

    def keywords
      @kwds.values.flatten.uniq.sort_by { |key| key.to_s }
    end

    def native_keywords
      @kwds[self.to_s].sort_by { |key| key.to_s }
    end

    def keyword_metadata
      @kwd_metadata ||= Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k]=Hash.new } }
      @kwd_metadata.values.inject(:merge)
    end

  private

    def create_new_keyword(name, map=nil, permissions, &block)
      keyword_name = name.to_sym
      add_to_keywords(keyword_name)
      add_to_current_process_page(keyword_name, permissions)
      add_keyword_metadata(keyword_name, map, permissions, block)
    end

    def add_keyword_metadata(name, map, permissions, block)
      @kwd_metadata ||= Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k]=Hash.new } }
      @kwd_metadata[self.to_s][name][:keyword] = name
      @kwd_metadata[self.to_s][name][:map] = map
      @kwd_metadata[self.to_s][name][:permissions] = permissions
      @kwd_metadata[self.to_s][name][:block] = block
      @kwd_metadata[self.to_s][name][:process_page] = @current_process_page
    end

    def add_to_current_process_page(name, permissions)
      @current_process_page << name if permissions
    end

    def add_to_keywords(method_sym)
      @kwds ||= Hash.new { |h, k| h[k] = Array.new }
      @kwds[self.to_s] << method_sym unless @kwds.include?(method_sym)
    end

    def add_superclass_keywords_to_subclass(klass)
      update_subclass_variables(klass, method='kwds', default=Hash.new { |h, k| h[k] = Array.new })
    end

    def add_superclass_keyword_metadata_to_subclass(klass)
      update_subclass_variables(klass, method='kwd_metadata', default=Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = Hash.new } })
    end

    def update_subclass_variables(klass, method, default)
      var = self.send(method)
      if var
        klass.send("#{method}=", default) unless klass.send(method)
        var.each_key do |k|
          klass.send(method).store(k, var.fetch(k).dup)
        end
      end
    end
  end

end
