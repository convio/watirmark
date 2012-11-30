module Watirmark
  module Model

    DebugModelValues = Hash.new{|h,k| h[k]=Hash.new}

    module DebugMethods
      def model_name=(name)
        @model_name = name
        add_debug_overrides
      end

      def add_debug_overrides
        return unless @model_name && DebugModelValues != {}
        Watirmark.logger.warn "Adding DEBUG overrides for #@model_name"
        update DebugModelValues['*'] if DebugModelValues['*']
        update DebugModelValues[@model_name] if DebugModelValues[@model_name]
      end
    end

  end
end
