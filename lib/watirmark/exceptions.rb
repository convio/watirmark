module Watirmark
  class Watirmark::MatcherNotFound < RuntimeError ;end
  class Watirmark::TestError < RuntimeError ;end
  class Watirmark::TestFailure < RuntimeError ;end
  class Watirmark::PostFailure < RuntimeError ;end
  class Watirmark::TDPage < RuntimeError; end
  class Watirmark::SecurityIssue < RuntimeError; end
  class Watirmark::WebPageElementNotFound < RuntimeError ;end
  class Watirmark::ModelNotFound < RuntimeError ;end
  class Watirmark::ModelCreationError < RuntimeError ;end
  class Watirmark::InvalidConfigurationFile < RuntimeError ;end
  class Watirmark::VerificationException < RuntimeError
    attr_accessor :actual, :expected
  end
end
