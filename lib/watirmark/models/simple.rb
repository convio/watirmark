module Watirmark
  module Model
    module Simple

      attr_accessor :__name__
      attr_reader :uuid

      def defaults
        {}
      end

      def initialize params = {}
        @__name__ = params if String === params
        if Watirmark::Configuration.instance.uuid
          @uuid = Watirmark::Configuration.instance.uuid
        else
          @uuid = UUID.new.generate(:compact)
        end
        update defaults
        update params unless String === params
        self
      end

      def uuid
        "#{__name__}_#{@uuid}"[0..40]
      end

      # adds a hash of values to the object
      def update hash
        hash.each_pair do |key, value|
          send "#{key}=", value
        end
        self
      end

      # does the model include the hash's values
      def includes? hash
        hash.each_pair do |key, value|
          return false unless send("#{key}") == value
        end
        true
      end

      #adds a hash of values to the object but only if it's set up in the struct
      def update_existing_members hash
        hash.each_pair do |key, value|
          send "#{key}=", value if respond_to? "#{key}=".to_sym
        end
        self
      end

      def to_h
        h = {}
        each_pair { |name, value| h[name] = value unless value.nil? }
        h
      end
    end
  end
end
