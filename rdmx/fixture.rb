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
