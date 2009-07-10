module Rdmx
  class Universe
    NUM_CHANNELS = 512

    attr_accessor :dmx, :values, :fixtures

    def initialize port, fixture_class=nil
      self.dmx = Rdmx::Dmx.new port
      self.values = Array.new NUM_CHANNELS
      self[0..-1] = 0 # set the universe to a known state
      self.fixtures = FixtureArray.new self, fixture_class
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

      def initialize universe, fixture_class=nil
        if fixture_class
          address = -1
          newborn = super(NUM_CHANNELS / fixture_class.channels.size) do
            fixture_class.new universe, *fixture_class.channels.map{address+=1}
          end
        else
          newborn = super(NUM_CHANNELS)
        end
        newborn.universe = universe
      end

      def replace klass
        super self.class.new(universe, klass)
      end
    end
  end
end
