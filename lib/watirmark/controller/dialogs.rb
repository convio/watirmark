module Watirmark
  module Dialogs
    def modal_exists?(window=Page.browser)
      !!(Page.browser.windows.size > 1)
    end

    def with_modal_dialog(window=Page.browser, &block)
      wait_for_modal_dialog(window)
      parent_window = (Page.browser.windows.size) - 2
      begin
        Page.browser.windows.last.use
        Page.browser.wait
        block.call
      ensure
        Page.browser.windows[parent_window].use
      end
    end

    def wait_for_modal_dialog(window=Page.browser)
      begin
        Timeout::timeout(30) {
          until modal_exists?
            sleep 0.002
          end
          Page.browser.wait
          sleep 0.02
        }
      rescue Timeout::Error
        raise Watirmark::TestError, 'Timed out while waiting for modal dialog to open'
      end
    end
  end
end