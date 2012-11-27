require 'watirmark/configuration'
Watirmark::Configuration.instance.defaults = {:create_master_snapshots => false}

module Watirmark
  module Screenshot

    class << self
      def take
        CurrentScreenShots.new
      end

      def compare_screenshots(masters, currents)
        raise ArgumentError, "Passed invalid arguments to compare_screenshots" unless masters.kind_of?(MasterAlbum) && currents.kind_of?(CurrentScreenShots)

        if Watirmark::Configuration.instance.snapshotwidth.kind_of?(Fixnum)
          compare_specific_screenshot_size(currents, masters)
        else
          compare_standard_screenshot_sizes(currents, masters)
        end
      end

      def compare_specific_screenshot_size(currents, masters)
         unless currents.screenshots.md5 == masters.album.md5
           report_failure(currents.screenshots.filename, masters.album.filename)
         end
      end

      def compare_standard_screenshot_sizes(currents, masters)
        masters.album.each_with_index do |master, index|
          unless currents.screenshots[index].md5  == master.md5
            report_failure(currents.screenshots[index].filename, masters.filename)
          end
        end
      end

      def report_failure(current, master)
        Watirmark.logger.info "Checking Snapshot:\n   master: #{master}\n   screenshot: #{current}"
        raise ArgumentError, "Master snapshot: #{File.expand_path(master)} does not match current snapshot: #{File.expand_path(current)}"
      end
    end

    class CurrentScreenShots
      attr_accessor :screenshots

      def initialize
        if Watirmark::Configuration.instance.snapshotwidth.kind_of?(Fixnum)
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
        if Watirmark::Configuration.instance.snapshotwidth.kind_of?(Fixnum)
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
        focus_browser
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

      def focus_browser
        Page.browser.element.click
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
        Watirmark.logger.info "Created new master: #@filename"
      end
    end
  end
end

