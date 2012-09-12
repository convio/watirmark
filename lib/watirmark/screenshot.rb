require 'watirmark/configuration'
Watirmark::Configuration.instance.defaults = {:create_master_snapshots => false}

module Watirmark
  module Screenshot

    def self.take
      Current.new
    end

    class Current
      attr_accessor :filename

      def initialize
        FileUtils.mkdir_p('reports/screenshots')
        @filename = "reports/screenshots/#{UUID.new.generate(:compact)}.png"
        Page.browser.screenshot.save @filename
      end

      def md5
        Digest::MD5.hexdigest(File.read(@filename))
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

