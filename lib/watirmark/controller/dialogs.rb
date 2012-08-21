module Watirmark
  module Dialogs
    def modal_exists?(window=Page.browser)
      if Watirmark::Configuration.instance.webdriver
        !!(Page.browser.windows.size > 1)
      else
        Page.browser.modal_dialog.exists?
      end
    end

    def with_modal_dialog(window=Page.browser, &block)
      wait_for_modal_dialog(window)
      if Watirmark::Configuration.instance.webdriver
        parent_window = (Page.browser.windows.size) - 2
        begin
          Page.browser.windows.last.use
          Page.browser.wait
          block.call
        ensure
          Page.browser.windows[parent_window].use if Page.browser.windows[parent_window]
        end
      else
        modal_hwnd = window.modal_dialog.hwnd
        block.call
        wait_until_modal_closed(window, modal_hwnd)
        wait_until_frames_loaded(window)
        wait_until_document_loaded(window)
      end
    end

    def wait_for_modal_dialog(window=Page.browser)
      begin
        if Watirmark::Configuration.instance.webdriver
          Timeout::timeout(30) {
            until modal_exists?
              sleep 0.002
            end
            Page.browser.wait
            sleep 0.02
          }
        else
          Timeout::timeout(30) {
            begin
              until modal_exists?(window) == true
                sleep 0.002
              end
              sleep 0.02
              until window.modal_dialog.document.readyState == 'complete'
                sleep 0.002
              end
            rescue WIN32OLERuntimeError
              retry
            end
          }
        end
      rescue Timeout::Error
        raise Watirmark::TestError, 'Timed out while waiting for modal dialog to open'
      end
    end

    def wait_until_modal_closed(window, hwnd=nil)
      return unless modal_exists?(window)
      return if hwnd && window.modal_dialog.hwnd != hwnd
      begin
        Timeout::timeout(30) {
          until modal_exists?(window) == false
            sleep 0.002
          end
        }
      rescue Timeout::Error
        raise Watirmark::TestError, 'Timed out while waiting for modal dialog to close'
      end
    end

    def wait_until_document_loaded(window)
      window.wait if window.document.readyState != 'complete'
    end

    def wait_until_frames_loaded(window)
      begin
        if Watirmark::Configuration.instance.webdriver
          Timeout::timeout(30) {
            return if window.document.frames.length == 0
            window.frames.each do |frame|
              begin
                Watir::Wait.until { frame.document.readyState == 'complete' }
              rescue Watir::Exception::FrameAccessDeniedException
                # ignore these frames which could be from another domain or not accessible (javascript-fu)
              end
            end
          }
        else
          Timeout::timeout(30) {
            begin
              return if window.document.frames.length == 0
              window.frames.each do |frame|
                begin
                  Watir::Wait.until { frame.document.readyState == 'complete' }
                rescue Watir::Exception::FrameAccessDeniedException
                  # ignore these frames which could be from another domain or not accessible (javascript-fu)
                end
              end
            rescue WIN32OLERuntimeError => e
              retry unless e.message =~ /unknown property or method `readyState'/
            end
          }
        end
      rescue Timeout::Error
        raise Watirmark::TestError, 'Timed out while waiting for frames to load'
      end
    end

    # Dialog is expected so wait for it and by default,
    # the title should be an exact match
    def close_dialog(window=nil, button='OK', exact_match=true, timeout=60, &block)
      block.call if block
      text = nil
      if window
        dialog = Page.browser.javascript_dialog(:title => window)
      else
        dialog = Page.browser.javascript_dialog
      end
      text = dialog.text
      dialog.button(button).click
      Watir::Wait.until {!Page.browser.javascript_dialog.exists?}    #wait on dialog to close
      browser.wait #wait on browser to refresh
      text
    end

    # Dialog may or may not be there so only wait a little and 
    # don't raise an error if not found
    def close_dialog_if_exists(window=nil, button='OK', exact_match=false, timeout=0, &block)
      block.call if block
      sleep 3.5
      text = nil
      if window
        dialog = Page.browser.javascript_dialog(:title => /#{window}/)
      else
        dialog = Page.browser.javascript_dialog
      end
      return unless Page.browser.javascript_dialog.exists?
      begin
        text = dialog.text
        dialog.button(button).click
        text
      rescue ::RAutomation::UnknownWindowException
      end
    end

  end
end