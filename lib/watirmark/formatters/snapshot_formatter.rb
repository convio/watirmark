require 'rspec/core/formatters/base_formatter'

module RSpec
  module Core
    module Formatters
      class SnapshotFormatter < BaseFormatter
        def initialize(output)
          super
          @path = output.path
        end

        def example_failed(example)
          begin
            browser = Page.browser
            snapshot = "#{Time.now.to_i}.html"
            f = File.open(File.join(@path.dirname, snapshot), 'w')
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