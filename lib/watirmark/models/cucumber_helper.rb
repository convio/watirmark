module Watirmark
  module Model

    module CucumberHelper

      def format_value(value)
        value = insert_model(value)
        case value
          when String
            if value[0, 1].eql?("=") #straight eval
              eval(value[1..value.length])
            elsif value == "true"
              true
            elsif value == "false"
              false
            elsif value.strip == ''
              nil
            else
              value
            end
          else
            value
        end
      end

      def insert_model(text)
        return text if text.class == String
        result = text
        regexp = /\[([^\[\]]+)\]\.(\w+)/
        while result =~ regexp #get value from models
          model_name = $1
          method     = $2
          value = DataModels[model_name].send method.to_sym
          result.sub!(regexp, value.to_s)
        end
        result
      end

      def merge_cucumber_table(cuke_table)
        cuke_table.rows_hash.each do |key, value|
          method_chain = key.to_s.split('.')
          method = method_chain.pop
          method_chain.inject(self) { |obj, m| obj.send m}.send "#{method}=", format_value(value)
        end
        Watirmark.logger.info "Updated #{inspect}"
        self
      end
    end
  end
end
