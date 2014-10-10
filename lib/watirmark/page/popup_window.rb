module Watirmark

  class PopupWindow
    include Watirmark::Dialogs

    attr_reader :parent, :keywords
    attr_accessor :alias, :name
    attr_accessor :submit_method, :navigate_method


    def initialize(name='', parent=nil, navigate_page=nil, submit_page=nil)
      @name = name
      @parent = parent #do we need parent?
      @keywords = []
      @alias = []
      @navigate_method = navigate_page if navigate_page
      @submit_method = submit_page if submit_page
    end

    def activate
      return if active?
      goto_process_page
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
      instance_eval &(@navigate_method)
    end

    def submit
      instance_eval &(submit_method)
    end

    def aliases
      @aliases ||= []
    end

    def active?
      modal_exists?
    end


  end
end