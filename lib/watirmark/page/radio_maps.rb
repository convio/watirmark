module Watirmark

  class RadioMapElement
    attr_accessor :list, :value

    def initialize(*args)
      @list= *args
      @value = nil
    end

    def map_to(x)
      @value = x
    end

    alias :maps_to :map_to

  end

  class RadioMap
    def initialize hash={}
      @maps = []
      hash.each_pair do |key, val|
        values(key).maps_to(val)
      end
    end

    def values(*args)
      element = RadioMapElement.new(*args)
      @maps << element
      element
    end

    alias :value :values

    def lookup(x)
      return nil if x.nil? || x == //
      @maps.each do |map|
        if Array === map.list
          map.list.each do |items|
            [*items].each do |item|
              return map.value if item.matches x
            end
          end
        else
          return map.value if map.list.matches x
        end
      end
      raise Watirmark::TestError, "No map value exists for '#{x}'" unless x
      x
    end
  end

end
