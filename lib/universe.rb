module Rdmx
  class Universe
    NUM_CHANNELS = 512
    class << self
      def all; @@all; end
      def all= new; @@all = new; end
    end

    attr_accessor :dmx, :values, :fixtures, :fixture_class

    def initialize port, fixture_class=nil
      @buffer = 0
      self.dmx = Rdmx::Dmx.new port
      self.values = Array.new NUM_CHANNELS
      self[0..-1] = 0 # set the universe to a known state
      self.fixture_class = fixture_class
      self.fixtures = FixtureArray.new self, fixture_class
      self.class.all ||= []
      self.class.all << self
    end

    # Build up writes and only write once
    def buffer &writes
      begin
        buffer_on!
        writes.call
      ensure
        buffer_off!
      end
      flush_buffer!
    end

    def buffer_on!; @buffer += 1; end
    def buffer_off!; @buffer -= 1; end

    def self.buffer &writes
      begin
        all.each &:buffer_on!
        writes.call
      ensure
        all.each &:buffer_off!
      end
      all.each &:flush_buffer!
    end

    def buffering?; @buffer > 0; end

    def flush_buffer!
      return if buffering?
      dmx.write values
    end

    def inspect
      "#<#{self.class}:#{dmx.device_name} #{values.inspect}>"
    end

    module Accessors
      def [] index
        self.values[index]
      end

      def []= channel, *new_values
        new_values.flatten!
        new_values = new_values * ([values[channel]].flatten.size / new_values.size) # extrapolate a pattern

        index = channel.respond_to?(:last) ? [channel].flatten : [channel, new_values.size]
        self.values[*index] = new_values
        flush_buffer! if respond_to?(:flush_buffer!)
      end
    end

    include Accessors

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
