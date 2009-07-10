module Rdmx
  class Universe
    NUM_CHANNELS = 512

    attr_accessor :dmx

    def initialize port
      self.dmx = Rdmx::Dmx.new port
      @values = Array.new NUM_CHANNELS
      self[0..-1] = 0 # set the universe to a known state
    end

    def []= channel, *values
      values.flatten!
      values = values * ([@values[channel]].flatten.size / values.size)
      last, index = if channel.respond_to?(:last)
        [channel.last, [channel].flatten]
      else
        [channel, [channel, values.size]]
      end
      @values[*index] = values
      data = @values[0..last]
      dmx.write data
    end
  end
end
