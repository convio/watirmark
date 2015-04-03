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
        # cucumber 2.0 defines a Core module between Cucumber and Ast
        doc_class = Cucumber::Ast.const_defined?(:DocString) ? Cucumber::Ast::DocString : Cucumber::Core::Ast::DocString
        return text unless text.class == String || text.class == doc_class
        result = text
        method_regexp = /\[([^\[\]]+)\]\.(\w+)/
        model_regexp = /\[([^\[\]]+)\]/
        if text =~ method_regexp
          while result =~ method_regexp #get value from models
            model_name = $1
            method     = $2
            value = DataModels[model_name].send method.to_sym
            result.sub!(method_regexp, value.to_s)
          end
        elsif text =~ model_regexp
          model_name = $1
          result = DataModels[model_name] if DataModels[model_name] != nil
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
