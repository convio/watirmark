module Watirmark
  module Dialogs

    def current_window_index
      current_window = Page.browser.window
      Page.browser.windows.find_index(current_window)
    end

    def modal_exists?
      Page.browser.window(index: current_window_index+1).exists?
    end

    def wait_for_modal_dialog
      Watir::Wait.until { modal_exists? }
    rescue TimeoutError
      raise Watirmark::TestError, 'Timed out while waiting for modal dialog to open'
    end

    def with_modal_dialog &blk
      wait_for_modal_dialog
      Page.browser.windows.last.use &blk
    end

    def close_chrome_windows
      Page.browser.windows(url: /chrome-extension/).each {|win| win.close}
    end

    def close_modal_window
      Page.browser.window(index: current_window_index+1).close if Page.browser.windows.size >= current_window_index
    end
  end
end