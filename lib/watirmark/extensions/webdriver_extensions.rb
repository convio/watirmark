require 'watir/elements/select'

module Watir

  module Container
    alias :row :tr
    alias :cell :td

    class DownloadLink < Anchor
      def initialize(*args)
        @dir = File.join(Watirmark::Configuration.instance.projectpath, "reports", "downloads")
        super
      end

      def download(file = nil)
        click
        locate_file(file)
      end

      def locate_file(file = nil)
        if file
          new_file = "#{@dir}/#{file}"
          File.delete(new_file) if File.file?(new_file)
          File.rename(last_modified_file, new_file)
          new_file
        else
          last_modified_file
        end
      end

      def last_modified_file
        Dir.new(@dir).select { |f| f!= '.' && f!='..' }.collect { |f| "#{@dir}/#{f}" }.sort { |a, b| File.mtime(b)<=>File.mtime(a) }.first
      end
    end

    def download_link(*args)
      DownloadLink.new(self, extract_selector(args).merge(:tag_name => "a"))
    end

    class DownloadLinkCollection < ElementCollection
      def element_class
        DownloadLink
      end
    end

    def download_links(*args)
      DownloadLinkCollection.new(self, extract_selector(args).merge(:tag_name => "a"))
    end
  end

  # module Atoms
  #   ATOMS[:getPreviousSibling] = File.read(File.expand_path("../atoms/getPreviousSibling.js", __FILE__))
  #   ATOMS[:getNextSibling] = File.read(File.expand_path("../atoms/getNextSibling.js", __FILE__))
  # end

  class Table < HTMLElement
    def each
      rows.each { |x| yield x }
    end
  end

  class TableRow < HTMLElement
    def each
      # TODO: not 100% sure this is a complete fix
      tds.each { |x| yield x }
    end

    def column(what)
      column = 0
      # TODO: not 100% sure this is a complete fix
      parent.th(:text => what).when_present.parent.ths.each do |cell|
        if what.kind_of? String
          return self[column] if cell.text == what
        else
          return self[column] if cell.text =~ what
        end
        column +=1 unless cell.text.strip == ''
      end
      raise Watir::Exception::UnknownObjectException, "unable to locate column, using '#{what}'"
    end
  end

  class CheckBox < Input
    alias :value= :set
  end

  class Radio < Input
    alias :old_radio_set :set

    def set(value=nil)
      if value
        @selector.update(:value => value.to_s)
        build
        locate
      end

      old_radio_set
    end

    alias :value= :set

    alias :old_radio_set? :set?

    def set?(value=nil)
      if value
        @selector.update(:value => value.to_s)
        build
        locate
      end

      old_radio_set?
    end
  end

  class Select
    alias :value= :select
    alias :set :select

    def getAllContents
      options.map(&:text)
    end
  end

  class Element

    # def next_sibling
    #   e = locate_dom_element(:getNextSibling)
    #   e.nil? ? element(xpath: './following-sibling::*') : e
    # end
    alias_method :nextsibling, :next_sibling
    #
    # def previous_sibling
    #   e = locate_dom_element(:getPreviousSibling)
    #   e.nil? ? element(xpath: './preceding-sibling::*') : e
    # end
    # alias_method :prev_sibling, :previous_sibling
    alias_method :prevsibling, :previous_sibling

    # def locate_dom_element(method)
    #   assert_exists
    #
    #   e = element_call { execute_atom method, @element }
    #
    #   if e.kind_of?(Selenium::WebDriver::Element)
    #     Watir.element_class_for(e.tag_name.downcase).new(@parent, :element => e)
    #   end
    # end

    # alias_method :old_element_call, :element_call
    # def element_call &block
    #   old_element_call &block
    # rescue Selenium::WebDriver::Error::UnknownError => ex
    #   raise unless ex.message.include?("Element is not clickable at point")
    #   reset!
    #   assert_exists
    #   retry
    # end

    alias_method :old_text, :text
    def text
      old_text.strip
    end

    def click_if_exists
      click if exists?
    end

    alias_method :click_no_wait, :click
  end

  class TextFieldLocator
    def check_deprecation(element)
      if element.tag_name.downcase == 'textarea'
        warn "Locating textareas with '#text_field' is deprecated. Please, use '#textarea' method instead for #{@selector}"
      end
    end
  end

  class IFrame < HTMLElement
    alias_method :old_switch_to!, :switch_to!
    def switch_to!
      retry_attempts ||= 0
      old_switch_to!
    rescue Watir::Exception::UnknownFrameException
      # UnknownFrameException is workaround for- https://code.google.com/p/chromedriver/issues/detail?id=948
      retry_attempts += 1
      retry if retry_attempts == 1
    end
  end

  class Alert
    alias_method :old_text, :text
    def text
      old_text.strip
    end
  end

  class Browser
    alias_method :old_text, :text
    def text
      old_text.strip
    end
  end

end

module Selenium
  module WebDriver
    module Chrome
      class Service
        alias :stop_original :stop
        def stop
          watirmark_close_browser
          stop_original
        end

        def watirmark_close_browser
          return if @process.nil? || @process.exited? || @stopped
          @stopped = true
          config = Watirmark::Configuration.instance
          Watirmark::Session.instance.closebrowser if config.closebrowseronexit || config.headless
        end
      end
    end
  end
end
