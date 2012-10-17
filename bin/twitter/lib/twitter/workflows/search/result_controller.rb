module Twitter
  module Search
    class Result < BaseController
      @model = ResultModel
      @view = ResultView

      def self.each
        @view.results.each {|item| yield item}
      end
    end
  end
end

