require 'watirmark/page/radio_maps'

module Watirmark

  module KeywordMethods
    attr_accessor :keyword, :radio_map
  end

  class KeyedElement
    attr_reader :keyword, :process_page, :permissions

    def initialize(context, options)
      @context      = context
      @keyword      = options[:keyword]
      @block        = options[:block]
      @process_page = options[:process_page]
      @permissions  = options[:permissions] || {}
      @map = Watirmark::RadioMap.new(options[:map]) if options[:map]
    end

    def get *args
      @process_page.activate
      watir_object = @context.instance_exec(*args, &@block)
      watir_object.extend(KeywordMethods)
      watir_object.radio_map = @map if @map
      watir_object.keyword = @keyword
      watir_object
    end

    def set val
      return if val.nil?
      element = get
      val = @map.lookup(val) if @map
      case val
        when 'nil'
          element.clear # workaround to empty element values
        else
          case element
            when Watir::Radio
              element.set val
            when Watir::CheckBox
              val ? element.set : element.clear
            when Watir::Select
              element.select val
            when Watir::Button
              element.click
            else
              element.value = val
          end
      end
    end

    def populate_allowed?
      @permissions[:populate]
    end

    def verify_allowed?
      @permissions[:verify]
    end

  end
end
