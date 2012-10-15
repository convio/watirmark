module Twitter
  module Search
    class QueryView < BaseView
      keyword(:search_term)  { browser.text_field(:id, 'search-query') }

      class << self
        def home(model)
        end

        def create(model)
        end

        def edit(model)
        end
      end
    end
  end
end
