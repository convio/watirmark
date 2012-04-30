module Watirmark
  module Model
    module UploadCSV
      require 'csv'
      require 'tempfile'

      def __create_csv__(table)
        log.info("Creating temporary CSV: #{__csv_file__}")
        log.info(table.inspect)
        CSV.open(__csv_file__, 'wb') do |csv|
          table.each do |line|
            csv << line
          end
        end
      end

      def __csv_file__
        @file ||= Tempfile.new(['csv_data', '.csv'])
        @file.path
      end

    end
  end
end
