module Watirmark
  class ProcessPage

    attr_reader :parent, :keywords
    attr_accessor :alias, :name, :root, :always_activate_parent
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

    def initialize(name='', parent=nil, active_page=nil, navigate_page=nil, submit_page=nil)
      @name = name
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
    def underscored_name(name=@name)
      u_name = (@parent && !@parent.root) ? "#{@parent.underscored_name}_#{name}" : name
      u_name.downcase.gsub(/\s+/, '_') if u_name
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
        raise Watirmark::TestError, "Unable to navigate to Process Page: #{name}" if aliases.empty?
        aliases.each do |alias_name|
          alias_process_page = self.dup
          alias_process_page.alias = []
          alias_process_page.name = alias_name
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

    def aliases
      @alias ||= []
    end

    def active?
      page = active_page
      return true if in_submenu(page, underscored_name)
      aliases.each { |a| return true if in_submenu(page, underscored_name(a)) } unless aliases.empty?
      false
    end

    def in_submenu(active_page, requested_page)
      !!(active_page.to_s.downcase.delete('>').gsub(/\s+/, '_') =~ /^#{requested_page}/)
    end

  end
end