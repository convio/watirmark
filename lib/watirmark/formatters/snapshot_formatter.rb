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
          begin
            browser = Page.browser
            append_text = example.description.gsub(/([^\w-])/, "_")
            snapshot = "#{Time.now.to_i} - #{append_text}.html"
            file = File.join(@path, snapshot)
            f = File.open(File.join(@path, snapshot), 'w')
            f.puts browser.html
            f.close
          rescue NameError => e
            # Page.browser not defined
          end
        end
      end
    end
  end
end