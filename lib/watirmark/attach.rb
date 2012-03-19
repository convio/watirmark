# Requiring this file from IRB will:
#   * Attach to the browser whose title matches the "window_title" enviroment 
#     variable. This can be a partial match.
#   * Enable tab completion.
#   * Store command history to the file ".irb_history".
#   * Load your personal .irbrc (as always).

require 'irb/completion'
ARGV.concat [ "--readline", "--prompt-mode", "simple" ]
RUBY_PLATFORM =~ /mswin/ ? history_file = '\.irb_history' : history_file =  '~/.irb_history'
IRB.conf[:EVAL_HISTORY] = 1000
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = File::expand_path(history_file)
require 'watirmark'


def attach(title)
  session = Watirmark::IESession.instance
  session.config.attach = true
  session.attach_title = Regexp.new(title)
  browser = session.openbrowser
  puts "Attached to: #{browser.title}"
end

title = ENV['window_title'] || '.'
attach /#{title}/
