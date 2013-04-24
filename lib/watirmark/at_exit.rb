module Watirmark
  def self.add_exit_task
    at_exit {
      if $!.nil? || $!.is_a?(SystemExit) && $!.success?
        code = 0
      else
        code = $!.is_a?(SystemExit) ? $!.status : 1
      end
      yield if block_given?
      exit code
    }
  end
end
