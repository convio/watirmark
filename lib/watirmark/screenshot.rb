require 'watirmark/configuration'
Watirmark::Configuration.instance.defaults = {:create_master_snapshots => false}

module Watirmark
  module Screenshot

    def self.take
      Current.new
    end

    class Current
      attr_accessor :filename, :screenwidth, :screenheight

      def initialize
        update_window_size
        FileUtils.mkdir_p('reports/screenshots')
        @filename = "reports/screenshots/#{UUID.new.generate(:compact)}.png"
        Page.browser.screenshot.save @filename
        revert_window_size
      end

      def md5
        Digest::MD5.hexdigest(File.read(@filename))
      end

      def update_window_size
        get_screen_size
        Page.browser.window.resize_to(Watirmark::Configuration.instance.snapshotwidth, Watirmark::Configuration.instance.snapshotheight)
      end

      def get_screen_size
        size = Page.browser.window.size
        @screenwidth = size.width
        @screenheight = size.height
      end

      def revert_window_size
        Page.browser.window.resize_to(@screenwidth, @screenheight)
      end
    end

    class Master < Current
      def initialize(filename, screenshot)
        update_window_size
        @filename = filename
        update(screenshot) if Watirmark::Configuration.instance.create_master_snapshots
        revert_window_size
      end

      def update(screenshot)
        FileUtils.mkdir_p(File.dirname(@filename))
        File.unlink(@filename) if File.exists?(@filename)
        FileUtils.copy_file(screenshot.filename, @filename)
        puts "Created new master: #{@filename}"
      end
    end

  end
end

