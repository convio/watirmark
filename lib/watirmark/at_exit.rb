module Watirmark
  def self.add_exit_task
    at_exit {
      code = $watirmark_exit
      yield if block_given?
      exit code if code
    }
  end
end
