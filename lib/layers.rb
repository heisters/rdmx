module Rdmx
  class Layers < Array
    attr_accessor :universe

    def initialize count, universe
      self.universe = universe
      super(count){|i|Rdmx::Layer.new(self)}
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
      self.values = parent.universe.values
      self.fixtures = Rdmx::Universe::FixtureArray.new self,
        parent.universe.fixture_class
    end

    def update_channel channel, *new_values
      new_values = extrapolate_pattern channel, new_values
      index = coerce_index channel, new_values.size
      blended = values[*index].each_with_index.map do |v, i|
        new_value = new_values[i]
        new_value ? [[v + new_values[i], 255].min, 0].max : v
      end
      self.values[*index] = blended
    end

    include Rdmx::Universe::Accessors # after redefinition so alias works
  end
end
