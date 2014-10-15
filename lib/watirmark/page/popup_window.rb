require 'watirmark/controller/dialogs'
module Watirmark

  class PopupWindow
    include Watirmark::Dialogs

    attr_reader :parent, :keywords
    attr_accessor :alias, :name
    attr_accessor :submit_method, :navigate_method

    @@navigate_method_default ||= Proc.new {}
    @@submit_method_default ||= Proc.new {}

    class << self
      def navigate_method_default=(proc)
        @@navigate_method_default = proc
      end

      def submit_method_default=(proc)
        @@submit_method_default = proc
      end

      def navigate_method_default
        @@navigate_method_default
      end

      def submit_method_default
        @@submit_method_default
      end
    end


    def initialize(name='', parent=nil, navigate_page=nil, submit_page=nil)
      @name = name
      @parent = parent #do we need parent?
      @keywords = []
      @root = false
      @alias = []
      @navigate_method = navigate_page if navigate_page
      @submit_method = submit_page if submit_page
    end

    def underscored_name(name=@name)
      name.downcase.gsub(/\s+/, '_')
    end

    def activate
      return if active?
      goto_popup_window
      Page.browser.windows.last.use
    end

    def <<(x)
      @keywords << x.to_sym
    end

    def goto_popup_window
      unless navigate
        aliases.each do |alias_name|
          alias_popup_window = self.dup
          alias_popup_window.alias = []
          alias_popup_window.name = alias_name
          alias_popup_window.alias = nil
          alias_popup_window.goto_popup_window
        end
      end
    end

    def navigate
      instance_eval &(@navigate_method || @@navigate_method_default)
    end

    def submit
      instance_eval &(submit_method || @@submit_method_default)
      Page.browser.windows.first.use
      Page.browser.windows.last.close
    end

    def aliases
      @aliases ||= []
    end

    def active?
      modal_exists?
    end


  end
end