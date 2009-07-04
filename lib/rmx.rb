#require 'rmx_ext'
require 'singleton'

class DriverConnector
  include Singleton

  def initialize
    @fd = File.open('/dev/dmx0', 'w')
    @channels = ["\x0"] * 513
  end

  def write(channel, value)
    @channels[channel] = "" << value
    @fd.syswrite @channels.join
  end
end

class Rmx

  attr_writer :frequency, :max_value

  MAX_VALUE = 230
  MIN_VALUE = 5

  attr_reader :channel

  @@instances = {}

  def value=(new_value)
    @value = new_value
    notify_value_change_listeners
    DriverConnector.instance.write(@channel, @value)
  end

  def self.new(*atts)
    return @@instances[atts[0]] if @@instances[atts[0]]
    super *atts
  end

  def initialize(channel)
    @channel = channel
    @@instances[channel] = self
    @value_change_listeners = []
    @max_value = MAX_VALUE
    @threads = []
  end

    # light turns on/off with given frequency
    def blink(frequency = 2.0)
      @frequency = frequency
      @running = true
      t = Thread.new do
            while(@running)
                self.value=@max_value
                sleep 0.5/@frequency
                self.value=MIN_VALUE
                sleep 0.5/(@frequency+0.1)
            end
        end
     @threads << t
    end

    # sends a short flash with the given frequency
    def flash(frequency = 4.0)
      @running = true
      @frequency = frequency
      t = Thread.new do
            while(@running)
                self.value=@max_value
                sleep 0.1
                self.value=MIN_VALUE
                sleep 1/(@frequency+0.1)
            end
        end
     @threads << t
    end

    # light fades in/out with given frequency
    def fade_blink(frequency = 1.0)
      @running = true
      @frequency = frequency
      t = Thread.new do
            while(@running)
                fade_in 0.5 / @frequency
                fade_out 0.5 / @frequency
            end
        end
      @threads << t
    end

    # fades in a new thread
    def fade(from = MIN_VALUE, to = @max_value, time = 2.0)
        @running = true
        t = Thread.new do
            _fade from, to, time
        end
        @threads << t
    end

  def off
    @running = false
    @threads.each {|t| t.join }
    @threads.clear
    self.value = 0
  end

  def add_value_change_listener(&block)
    @value_change_listeners << block
  end


    private

    def notify_value_change_listeners
      @value_change_listeners.each {|listener|
        listener.call @value
      }
    end

    # fades from 0 to 255
    def fade_in(time = 1.0)
        _fade MIN_VALUE, @max_value, time
    end

    # fade from 255 to 0
    def fade_out(time = 1.0)
        _fade @max_value, MIN_VALUE, time
    end

    def fadestep(_value, from, to, time)
      if _value.to_i % 10 == 0
        self.value = _value.to_i
        sleep time / (to-from).abs * 10
      end
    end

    # fades in the current thread
    def _fade(from = MIN_VALUE, to = @max_value, time = 2.0)
      if from < to
        from.to_i.upto to.to_i do |i|
          return unless @running
          fadestep i, from, to, time
        end
      else
        from.to_i.downto to.to_i do |i|
          return unless @running
          fadestep i, from, to, time
        end
      end
    end
end
