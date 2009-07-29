module Rdmx
  class Fixture
    attr_accessor :channels, :universe

    def initialize universe, *addresses
      self.universe = universe
      self.channels = {}
      raise ArgumentError, "expected #{self.class.channels.size} addresses" unless
        self.class.channels.size == addresses.size
      self.class.channels.zip(addresses).each do |name, address|
        self.channels[name] = address
      end
    end

    def all
      self.class.channels.map do |key| # preserve order!
        universe[channels[key]]
      end
    end

    def all= *values
      values.flatten!
      values = values * channels.size if values.size == 1
      raise ArgumentError, "expected #{channels.size} values" unless values.size == channels.size
      values.zip(self.class.channels).each do |value, key| # preserve order!
        universe[channels[key]] = value
      end
    end

    def inspect
      "#<#{self.class} #{channels.inspect}>"
    end

    class << self
      def channels; @channels; end
      def channels= *names
        @channels = names.flatten

        channels.each do |name|
          define_method "#{name}" do
            universe[channels[name]]
          end

          define_method "#{name}=" do |value|
            universe[channels[name]] = value
          end
        end
      end
    end
  end
end
