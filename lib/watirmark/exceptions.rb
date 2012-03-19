module Watirmark

  # This is probably what you should use
  class Watirmark::TestError < RuntimeError ;end
  # Use this to abort your test
  class Watirmark::TestFailure < RuntimeError ;end
  # Use this in error-checkers.
  class Watirmark::PostFailure < RuntimeError ;end
  class Watirmark::TDPage < RuntimeError; end
  class Watirmark::SecurityIssue < RuntimeError; end
  class Watirmark::WebPageElementNotFound < RuntimeError ;end
  class Watirmark::VerificationException < RuntimeError
    attr_accessor :actual, :expected
  end
end
