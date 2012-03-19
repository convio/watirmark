# Work around Jenkins issue where dialogs not clicked
module RAutomation
  module Adapter
    module WinFfi
      class Control
         def click
          assert_enabled
          clicked = false
          wait_until do
            hwnd = Functions.control_hwnd(@window.hwnd, @locators)

            if hwnd
              Functions.control_click(hwnd) &&
              clicked = true # is clicked at least once
            end

            block_given? ? yield : clicked && !exist?
          end
        end
      end
      class TextField < Control
        def set(text)
          raise "Cannot set value on a disabled text field" if disabled?
          wait_until do
            hwnd = Functions.control_hwnd(@window.hwnd, @locators)
            Functions.set_control_text(hwnd, text) && value == text
          end
        end
      end
    end
  end
end
