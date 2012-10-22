require 'watirmark/page/radio_maps'

module Watirmark

  module KeywordMethods
    attr_accessor :keyword, :radio_map
  end

  class KeyedElement
    def initialize(options)
      @options = options
    end

    def get *args
      activate_process_page
      watir_object = @options[:page].instance_exec(*args, &@options[:block])
      watir_object.extend(KeywordMethods)
      watir_object.keyword = @options[:key]
      watir_object
    end

    def set val
      return if val.nil?
      activate_process_page
      element = get
      val = Watirmark::RadioMap.new(@options[:map]).lookup(val) if @options[:map]
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

    def activate_process_page
      raise ArgumentError, "No process page defined! This should never happen" unless @options[:process_page]
      @options[:process_page].activate
    end
  end
end
