module Rdmx
  class Layers < Array
    attr_accessor :universe

    def initialize count, universe
      self.universe = universe
      super(count){|i|Rdmx::Layer.new(self)}
    end

    def apply!
      universe.values = blend
    end

    def blend
      inject(Array.new(universe.values.size, 0)) do |blended, layer|
        layer.values.each_index do |i|
          blended[i] = [([(blended[i] + layer[i]), 255].min), 0].max
        end
        blended
      end
    end

    def push *obj
      if obj.empty? || (obj.size == 1 && obj.first.is_a?(Integer))
        num = obj.pop || 1
        obj = num.times.map{Rdmx::Layer.new(self)}
      end
      super(*obj)
    end
  end

  class Layer
    include Rdmx::Universe::Accessors

    attr_accessor :values, :fixtures

    def initialize parent
      self.values = parent.universe.values.clone
      self.fixtures = Rdmx::Universe::FixtureArray.new self,
        parent.universe.fixture_class
    end
  end
end
