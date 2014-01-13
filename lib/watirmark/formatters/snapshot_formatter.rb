require 'rspec/core/formatters/base_formatter'

module RSpec
  module Core
    module Formatters
      class SnapshotFormatter < BaseFormatter
        def initialize(output)
          super
          @path=output.path + "_dir/"
          Dir.mkdir(@path) if not File::directory?( @path )
        end

        def example_failed(example)
          if Page.browser_exists?
            append_text = example.description.gsub(/([^\w-])/, "_")
            snapshot = "#{Time.now.to_i} - #{append_text}.png"
            Page.browser.screenshot.save "#{@path}/#{snapshot}"
          end
        rescue Exception => e
          # an exception occurred.  We don't want exception to occur here or we'll get false positive test results.
          Watirmark.logger.warn "An exception was rescued in example_failed for SnapshotFormatter.  This exception is ignored"
        end
      end
    end
  end
end