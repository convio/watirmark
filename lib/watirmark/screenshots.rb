if Watirmark::Configuration.instance.webdriver
  FileUtils.rm_rf('reports')
  FileUtils.mkdir_p('reports/screenshots')
  Page.browser.screenshot.base64
end