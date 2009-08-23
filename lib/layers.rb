require 'narray'
module Rdmx
  class Layers < Array
    attr_accessor :universe
    attr_reader :use_alpha

    def initialize count, universe
      self.universe = universe
      @use_alpha = false
      super(count){|i|Rdmx::Layer.new(self)}
    end

    def apply!
      universe.values.replace composite
    end

    def alpha_on!
      @use_alpha = true
    end

    def alpha_off!
      @use_alpha = false
    end

    def self.alpha_compositor
      last = nil
      lambda do |composite, layer|
        alpha = layer.alpha
        alpha -= last.alpha if last
        alpha = alpha.greater_of(0)
        masked = layer.values
        if last
          mask = last.values <= 0
          masked = masked * alpha
          masked[mask] = layer.values[mask]
        else
          masked *= alpha
        end
        composite += masked
        last = layer
        composite
      end
    end

    def self.addition_compositor
      lambda do |composite, layer|
        composite + layer.values
      end
    end

    # See http://en.wikipedia.org/wiki/Alpha_compositing
    def composite
      compositor = use_alpha ? :alpha : :addition
      compositor = self.class.send "#{compositor}_compositor"
      composite = reverse.inject(NArray.float(universe.values.size), &compositor)
      composite[composite.gt 255] = 255
      composite[composite.lt 0] = 0
      composite.to_a
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
    attr_accessor :values, :fixtures, :parent, :alpha

    def initialize parent
      self.alpha = 1.0
      self.parent = parent
      self.values = NArray.float parent.universe.values.size
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
