module Rdmx
  class Universe
    NUM_CHANNELS = 512

    attr_accessor :dmx, :values, :fixtures

    def initialize port
      self.dmx = Rdmx::Dmx.new port
      self.values = Array.new NUM_CHANNELS
      self[0..-1] = 0 # set the universe to a known state
      self.fixtures = FixtureArray.new self
    end

    def []= channel, *new_values
      new_values.flatten!
      new_values = new_values * ([values[channel]].flatten.size / new_values.size)
      last, index = if channel.respond_to?(:last)
        [channel.last, [channel].flatten]
      else
        [channel, [channel, new_values.size]]
      end
      self.values[*index] = new_values
      data = self.values[0..last]
      dmx.write data
    end


    class FixtureArray < Array
      attr_accessor :universe
      def initialize universe, size=NUM_CHANNELS
        newborn = super(size)
        newborn.universe = universe
      end

      def replace klass
        address = -1
        replacement = self.class.new(universe, NUM_CHANNELS / klass.channels.size) do |i|
          klass.new universe, *klass.channels.map{address+=1}
        end
        super replacement
      end
    end
  end
end
