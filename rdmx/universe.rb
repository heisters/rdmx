module Rdmx
  class Universe
    NUM_CHANNELS = 512

    attr_accessor :dmx, :values, :fixtures

    def initialize port, fixture_class=nil
      @buffer = false
      self.dmx = Rdmx::Dmx.new port
      self.values = Array.new NUM_CHANNELS
      self[0..-1] = 0 # set the universe to a known state
      self.fixtures = FixtureArray.new self, fixture_class
    end

    def []= channel, *new_values
      new_values.flatten!
      new_values = new_values * ([values[channel]].flatten.size / new_values.size) # extrapolate a pattern

      self.update_values_delta channel, new_values
      flush_buffer!
    end

    def update_values_delta channel, new_values
      @values_delta ||= values.dup
      index = channel.respond_to?(:last) ? [channel].flatten : [channel, new_values.size]
      @values_delta[*index] = new_values
    end

    def values_delta
      last_changed = @values_delta.zip(values).rindex{|new, old|new != old} or return
      @values_delta[0..last_changed]
    end

    # Build up writes and only write once
    def buffer &writes
      @buffer = true
      writes.call
    ensure
      @buffer = false
      flush_buffer!
    end

    def buffering?; !!@buffer; end

    def flush_buffer!
      return if buffering?
      vd = values_delta or return
      dmx.write vd
      self.values[0...vd.size] = vd
      @values_delta = nil
    end

    class FixtureArray < Array
      attr_accessor :universe

      # fixture_class can be nothing, a class, or a hash denoting the number of
      # fixtures to create:
      #
      #  FixtureArray.new universe
      #  FixtureArray.new universe, MyFixture
      #  FixtureArray.new universe, MyFixture => 20
      def initialize universe, fixture_class=nil
        klass, size = *case fixture_class
        when Class then [fixture_class, (NUM_CHANNELS / fixture_class.channels.size)]
        when Hash then fixture_class.to_a.flatten
        else; [nil, NUM_CHANNELS]
        end

        address = -1
        newborn = super(size) do
          klass.new universe, *klass.channels.map{address+=1} if klass
        end
        newborn.universe = universe
      end

      def replace klass
        super self.class.new(universe, klass)
      end
    end
  end
end
