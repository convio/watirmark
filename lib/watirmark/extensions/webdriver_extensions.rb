require 'watir-webdriver/extensions/select_text'

Watir::always_locate = false

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

  class Table < HTMLElement
    def each
      rows.each { |x| yield x }
    end
  end

  class TableRow < HTMLElement
    def each
      cells.each { |x| yield x }
    end

    def column(what)
      column = 0
      parent.th(:text => what).when_present.parent.cells.each do |cell|
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
      @selector.update(:value => value.to_s) if value
      old_radio_set
    end

    alias :value= :set

    alias :old_radio_set? :set?

    def set?(value=nil)
      @selector.update(:value => value.to_s) if value
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
    begin
      alias :prev_sibling :previous_sibling
      alias :prevsibling :previous_sibling
      alias :nextsibling :next_sibling
    rescue NameError
      # not using convio-specific webdriver. Ignore and continue
    end

    def click_if_exists
      click if exists?
    end

    alias :click_no_wait :click
  end

  class TextFieldLocator
    def validate_element(element)
      if element.tag_name.downcase == 'textarea'
        warn "Locating textareas with '#text_field' is deprecated. Please, use '#textarea' method instead for #{@selector}"
      end
      super
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