module Watirmark
  module Model
    class DefaultValues < Hash

      # This is a workaround for zip being defined in Enumerable and
      # we want to use zip in the model as a zip code
      undef :zip

      # This works around an issue that gets hit when
      # running from rake and the model has default.desc set.
      # If we don't have it here it thinks we're trying to call rakes' #desc
      def desc(&block)
        self[:desc] = block
      end

      def method_missing(name, &block)
        self[name] = block
      end
    end
  end
end