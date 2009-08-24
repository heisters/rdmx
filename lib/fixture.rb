module Rdmx
  class Fixture
    attr_accessor :channels, :universe

    def initialize universe, *addresses
      self.universe = universe
      raise ArgumentError, "expected #{self.class.channels.size} addresses" unless
        self.class.channels.size == addresses.size

      self.channels = {}
      self.class.channels.zip(addresses).each do |name, address|
        self.channels[name] = address
      end
    end

    def all
      self.class.channels.map do |key| # preserve order!
        self.send key
      end
    end

    def expand_values values
      values.flatten!
      values = values * channels.size if values.size == 1
      raise ArgumentError, "expected #{channels.size} values" unless values.size == channels.size
      values
    end

    def all= *values
      values = expand_values values
      values.zip(self.class.channels).each do |value, key| # preserve order!
        self.send "#{key}=", value
      end
    end

    def ensure_alpha_supported!
      raise "Alpha is not supported by #{universe.inspect}" unless universe.respond_to?(:alpha)
    end

    def alpha
      ensure_alpha_supported!
      self.class.channels.map do |key|
        universe.alpha[channels[key]]
      end
    end

    def alpha= *values
      ensure_alpha_supported!
      values = expand_values values
      values.zip(self.class.channels).each do |value, key|
        universe.alpha[channels[key]] = value
      end
    end

    def inspect
      "#<#{self.class} #{channels.inspect}>"
    end

    class << self
      attr_reader :channels
      def channels= *names
        @channels = names.flatten
        # use eval instead of define_method, since closures are slow
        # see http://olabini.com/blog/2008/05/dynamically-created-methods-in-ruby/
        @channels.each do |name|
          class_eval <<-EVAL
            def #{name}
              universe[channels[#{name.inspect}]]
            end

            def #{name}= value
              universe[channels[#{name.inspect}]] = value
            end
          EVAL
        end
      end
    end
  end
end
