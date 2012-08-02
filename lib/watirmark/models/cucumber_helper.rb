module Watirmark
  module Model

    module CucumberHelper

      def format_value(value)
        if String === value && value[0, 1].eql?("=") #straight eval
          eval(value[1..value.length])
        elsif value == "true"
          return true
        elsif value == "false"
          return false
        else
          insert_model(value)
        end
      end

      def insert_model(text)
        result = text
        regexp = /\[([^\]]+)\]\.(\w+)/
        while result =~ regexp #get value from models
          model_name = $1
          method     = $2
          value = DataModels.instance[model_name].send method.to_sym
          result.sub!(regexp, value.to_s)
        end
        result
      end

      def merge_cucumber_table(cuke_table)
        cuke_table.rows_hash.each do |key, value|
          method_chain = key.split('.')
          method = method_chain.pop
          method_chain.inject(self) { |obj, m| obj.send m}.send "#{method}=", format_value(value)
        end
        @log.info "Updated #{inspect}"
        self
      end
    end
  end
end
