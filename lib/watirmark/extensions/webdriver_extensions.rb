if Watirmark::Configuration.instance.webdriver
  require 'watir-webdriver'
  require 'watir-webdriver/extensions/select_text'

  # Allows us to silently ignore this exception which will never apply.
  # Once we're on webdriver completely we can remove all references to this
  # exception
  class WIN32OLERuntimeError < RuntimeError;
  end
  class WIN32OLE < RuntimeError;
  end

  module Watir

    class Browser
      # for modal dialogs that close on submission, these might
      # fail to run because the window has been destroyed
      alias :old_run_checkers :run_checkers

      # this is basically a check to make sure we're not
      # running the checkers on a modal dialog that has closed
      # by the time the checkers have run
      def run_checkers
        @error_checkers.each { |e| e.call(self) unless $in_model_dialog || windows.size > 1}
      end
    end

    module RowContainer

      alias :old_row :row

      def row(*args)
        if has_cell?(args)
          rows(*transform_has_cell_args(args)).last
        else
          old_row(*args)
        end
      end
    end

    module Container

      def modal_dialog
        raise "WebDriverImplementation!! Need to be using 'with_modal_dialog' block" unless $in_modal_dialog
        browser
      end

      def row(*args)
        if has_cell?(args)
          located_rows = trs(*transform_has_cell_args(args))
          if located_rows.size > 0
            located_rows.last
          else
            tr(*transform_has_cell_args(args))
          end
        else
          tr(*args)
        end
      end

      alias :old_table :table

      def table(*args)
        if has_cell?(args)
          located_tables = tables(*transform_has_cell_args(args))
          if located_tables.size > 0
            located_tables.last
          else
            table(*transform_has_cell_args(args))
          end
        else
          old_table(*args.flatten)
        end
      end

      alias :cell :td

      def has_cell?(args)
        case args
          when Hash
            return true if args[:has_cell]
          when Array
            return true if args[0] == :has_cell
        end
        false
      end

      private :has_cell?

      def transform_has_cell_args(args)
        case args
          when Hash
            val = args[:has_cell]
            args.delete(:has_cell)
            case val
              when String
                args[:text] = /^\s*#{Regexp.escape(val)}\s*$/
              when Regexp
                args[:text] = val
            end
          when Array
            args[0] = :text
            case args[1]
              when String
                args[1] = /^\s*#{Regexp.escape(args[1])}\s*$/
            end
        end
        args
      end

      private :transform_has_cell_args

    end

    class Table < HTMLElement
      def each
        rows.each { |x| yield x }
      end
    end

    class TableRow < HTMLElement
      def each
        cells.each { |x| yield x }
      end

      def column(what)
        column = 0
        parent.th(:text => what).when_present.parent.cells.each do |cell|
          if what.kind_of? String
            return self[column] if cell.text == what
          else
            return self[column] if cell.text =~ what
          end
          column +=1 unless cell.text.strip == ''
        end
        raise Watir::Exception::UnknownObjectException, "unable to locate column, using '#{what}'"
      end
    end

    class CheckBox < Input
      alias :value= :set
    end

    class Radio < Input
      alias :old_radio_set :set

      def set(value=nil)
        @selector.update(:value => value.to_s) if value
        old_radio_set
      end

      alias :value= :set

      alias :old_radio_set? :set?

      def set?(value=nil)
        @selector.update(:value => value.to_s) if value
        old_radio_set?
      end
    end

    class Select
      alias :value= :select
      alias :set :select

      def getAllContents
        options.map(&:text)
      end
    end

    class Element
      alias :prev_sibling :previous_sibling
      alias :prevsibling :previous_sibling
      alias :nextsibling :next_sibling

      def click_if_exists
        click if exists?
      end

      alias :click_no_wait :click
    end

  end
end