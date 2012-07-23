module Watirmark
  module Model
    class Defaults
      include Enumerable

      def initialize
        @members = []
      end


      def method_missing(name, *args, &block)
        name = name.to_s.gsub('=','')
        @members << name unless @members.include? name

        if block
          instance_variable_set "@#{name}", instance_eval(&Proc.new{block})
        else
          instance_variable_set "@#{name}", args.first
        end

        meta_def name do
          instance_variable_get "@#{name}"
        end
      end


      def each
        @members.each {|i| yield i}
      end
    end
  end
end