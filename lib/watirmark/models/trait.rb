require 'singleton'
module Watirmark
  module Model
    def self.trait(name, &block)
      Watirmark::Model::Traits.instance[name] = block
    end

    class Traits < Hash
      include Singleton
    end
  end
end