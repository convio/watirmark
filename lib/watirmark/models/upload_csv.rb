module Watirmark
  module Model
    class UploadCSV < Base
      require 'csv'
      require 'tempfile'

      def create_csv(table)
        Watirmark.logger.info "Creating temporary CSV: #{csv_file}"
        Watirmark.logger.info table.inspect
        CSV.open(csv_file, 'wb') do |csv|
          table.each do |line|
            csv << line
          end
        end
      end

      def csv_file
        @file ||= Tempfile.new(%w(csv_data .csv))
        @file.path
      end

    end
  end
end
