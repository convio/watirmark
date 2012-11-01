module Watirmark
  class ProcessPage

    attr_reader :parent, :keywords
    attr_accessor :alias, :page_name, :root, :always_activate_parent
    attr_accessor :submit_method, :active_page_method, :navigate_method

    @@navigate_method_default ||= Proc.new {}
    @@submit_method_default ||= Proc.new {}
    @@active_page_method_default ||= Proc.new {}

    class << self
      def navigate_method_default=(proc)
        @@navigate_method_default = proc
      end

      def submit_method_default=(proc)
        @@submit_method_default = proc
      end

      def active_page_method_default=(proc)
        @@active_page_method_default = proc
      end

      def navigate_method_default
        @@navigate_method_default
      end

      def submit_method_default
        @@submit_method_default
      end

      def active_page_method_default
        @@active_page_method_default
      end
    end

    def initialize(page_name=nil, parent=nil, active_page=nil, navigate_page=nil, submit_page=nil)
      @page_name = page_name
      @parent = parent
      @keywords = []
      @root = false
      @always_activate_parent = false
      @alias = []
      @active_page_method = active_page if active_page
      @navigate_method = navigate_page if navigate_page
      @submit_method = submit_page if submit_page
    end

    # Give the full name of this process page, including the
    # parent process pages. The argument allows us to
    # easily get the full path for alias names.
    def name(page_name=@page_name)
      name = (@parent && !@parent.root) ? "#{@parent.name}_#{page_name}" : page_name
      name.downcase.gsub(/\s+/, '_')
    end

    def activate
      return if (@root || active?)
      if @always_activate_parent
        @parent.goto_process_page
      else
        @parent.activate if @parent
      end
      goto_process_page
    end

    def <<(x)
      @keywords << x.to_sym
    end

    def goto_process_page
      unless navigate
        @alias ||= []
        @alias.each do |alias_name|
          alias_process_page = self.dup
          alias_process_page.alias = []
          alias_process_page.page_name = alias_name
          alias_process_page.alias = nil
          alias_process_page.goto_process_page
        end
      end
    end

    def navigate
      instance_eval &(@navigate_method || @@navigate_method_default)
    end

    def submit
      instance_eval &(@submit_method || @@submit_method_default)
    end

    def active_page
      instance_eval &(@active_page_method || @@active_page_method_default)
    end

    def active?
      page = active_page
      return true if in_submenu(page, name)
      @alias.each { |a| return true if in_submenu(page, name(a)) } unless @alias.empty?
      false
    end

    def in_submenu(active_page, requested_page)
      active_page =~ /^#{requested_page}/
    end

  end
end