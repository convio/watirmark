module Twitter
  module Search
    class ResultView < BaseView
      private_keyword(:result_container)  { browser.div(:id => 'stream-items-id')}
      private_keyword(:results)           { result_container.divs(:class, 'content').map(&:text)}

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
