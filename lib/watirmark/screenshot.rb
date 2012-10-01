require 'watirmark/configuration'
Watirmark::Configuration.instance.defaults = {:create_master_snapshots => false}

module Watirmark
  module Screenshot

    def self.take
      CurrentScreenShots.new
    end

    def self.compare_screenshots(masters, currents)
      raise ArguementError, "Passed invalid arguments to compare_screenshots" unless masters.class == MasterAlbum && currents.class == CurrentScreenShots

      if Watirmark::Configuration.instance.snapshotwidth.class == Fixnum
        puts "Checking Snapshot:\n   master: #{masters.album.filename}\n   screenshot: #{currents.screenshots.filename}"
        raise ArgumentError, "Master snapshot: #{masters.album.md5} does not match current snapshot: #{currents.screenshots.md5}" unless masters.album.md5 == currents.screenshots.md5
      else
        masters.album.each_with_index do |master, index|
          puts "Checking Snapshot:\n   master: #{master.filename}\n   screenshot: #{currents.screenshots[index].filename}"
          raise ArgumentError, "Master snapshot: #{master.md5} does not match current snapshot: #{currents.screenshots[index].md5}" unless master.md5 == currents.screenshots[index].md5
        end
      end
    end

    class CurrentScreenShots
      attr_accessor :screenshots

      def initialize
        if Watirmark::Configuration.instance.snapshotwidth.class == Fixnum
          @screenshots = Current.new
        else
          widths = Watirmark::Configuration.instance.snapshotwidth.split(",").map {|s| s.to_i}
          @screenshots = []
          widths.each {|width| @screenshots << Current.new(width) }
        end
      end
    end

    class MasterAlbum
      attr_accessor :album

      def initialize(filename, screenshot)
        if Watirmark::Configuration.instance.snapshotwidth.class == Fixnum
          @album = Master.new(filename, screenshot.screenshots)
        else
          widths = Watirmark::Configuration.instance.snapshotwidth.split(",").map {|s| s.to_i}
          @album = []
          widths.each_with_index do |width, index|
            @album << Master.new(filename.sub(/\.png/, "_width_#{width}.png"), screenshot.screenshots[index])
          end
        end
      end
    end

    class Current
      attr_accessor :filename, :screenwidth, :screenheight

      def initialize(snapshotwidth=Watirmark::Configuration.instance.snapshotwidth)
        get_screen_size
        FileUtils.mkdir_p('reports/screenshots')
        take_screen_shot(snapshotwidth)
        revert_window_size
      end

      def take_screen_shot(snapshotwidth)
        update_window_size(snapshotwidth)
        @filename = "reports/screenshots/#{UUID.new.generate(:compact)}.png"
        Page.browser.window.use
        Page.browser.screenshot.save @filename
      end

      def md5
        Digest::MD5.hexdigest(File.read(@filename))
      end

      def update_window_size(width)
        Page.browser.window.resize_to(width, Watirmark::Configuration.instance.snapshotheight)
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
        @filename = filename
        update(screenshot) if Watirmark::Configuration.instance.create_master_snapshots
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

