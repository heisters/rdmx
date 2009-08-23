require 'narray'
module Rdmx
  class Layers < Array
    attr_accessor :universe

    def initialize count, universe
      self.universe = universe
      super(count){|i|Rdmx::Layer.new(self)}
    end

    def apply!
      universe.values.replace blend
    end

    def blend
      blend = inject(NArray.int(universe.values.size)) do |blended, layer|
        blended + layer.values
      end
      blend[blend.gt 255] = 255
      blend[blend.lt 0] = 0
      blend.to_a
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
    attr_accessor :values, :fixtures, :parent

    def initialize parent
      self.parent = parent
      self.values = NArray.int parent.universe.values.size
      self.fixtures = Rdmx::Universe::FixtureArray.new self,
        parent.universe.fixture_class
    end

    def [] *args
      values.send :[], *args
    end

    def []= *args
      values.send :[]=, *args
    end
  end
end
