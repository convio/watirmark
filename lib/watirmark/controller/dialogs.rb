module Watirmark
  module Dialogs

    # Assumes 2 windows
    def modal_exists?
      Page.browser.window(:index, 1).exists?
    end

    # Uses last window
    def with_modal_dialog &blk
      wait_for_modal_dialog
      Page.browser.windows.last.use &blk
    end

    # TODO - Depricate when implement smart_waits
    def wait_for_modal_dialog
      Watir::Wait.until { modal_exists? && Page.browser.wait}
    rescue TimeoutError
      raise Watirmark::TestError, 'Timed out while waiting for modal dialog to open'
    end

    def close_chrome_windows
      chrome_window = Page.browser.window(:url, /chrome-extension/)
      chrome_window.close if chrome_window.exists?
    end

    # Assumes 2 windows
    def close_modal_window
      Page.browser.window(:index, 1) if modal_exists?
    end

  end
end