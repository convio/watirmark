module Twitter
  module Search
    class Query < BaseController
      @model = QueryModel
      @view = QueryView

      def submit
        @view.search_term.parent.submit
      end
    end
  end
end

