module Watirmark
  def self.add_exit_task &block
    at_exit {
      if $!.nil? || $!.is_a?(SystemExit) && $!.success?
        code = 0
      else
        code = $!.is_a?(SystemExit) ? $!.status : 1
      end
      block.call if block
      exit code
    }
  end
end