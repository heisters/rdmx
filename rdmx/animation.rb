require 'fiber'
module Rdmx
  class Animation
    attr_accessor :storyboard, :root_frame

    FPS = Rdmx::Dmx::DEFAULT_PARAMS['baud'] / (8 * (Rdmx::Universe::NUM_CHANNELS + 6))
    FRAME_DURATION = 1.0 / FPS

    public :sleep

    def initialize &storyboard
      self.storyboard = storyboard
      self.root_frame = Frame.new do
        storyboard.call
        loop do
          root_frame.children.each do |frame|
            Rdmx::Universe.buffer do
              frame.resume if frame.alive? || frame.children.any?(&:alive?)
            end
            Fiber.yield sleep(FRAME_DURATION)
          end
          break unless root_frame.all_children.any?(&:alive?)
        end
      end
    end

    def storyboard_receiver
      storyboard.binding.eval('self')
    end

    def storyboard_metaclass
      (class << storyboard_receiver; self; end)
    end

    def mixin!
      @storyboard_old_method_missing = storyboard_receiver.method :method_missing
      dsl = self
      storyboard_metaclass.send :define_method, :method_missing do |m, *a, &b|
        if dsl.respond_to?(m)
          dsl.send m, *a, &b
        else
          @storyboard_old_method_missing.call m, *a, &b
        end
      end
    end

    def mixout!
      storyboard_metaclass.send :define_method, :method_missing,
        &@storyboard_old_method_missing
    end

    def with_mixin &block
      mixin!
      yield
    ensure
      mixout!
    end

    def go_once!
      with_mixin{root_frame.resume if root_frame.alive?}
    end

    def go!
      with_mixin do
        while root_frame.alive?
          root_frame.resume
        end
      end
    end

    def frame insert_yield=true, &frame
      Frame.new(
        Frame.current,
        &(insert_yield ? lambda{Fiber.yield frame.call} : frame)
      )
    end

    class Frame < Fiber
      attr_accessor :parent, :children
      def initialize parent=nil, &block
        super(&block)
        self.children = []
        self.parent = parent
        parent.children << self if parent
      end

      def resume *args
        super(*args) if alive?
        children.each{|c|c.resume(*args) if c.alive?} if parent
      end

      def all_children
        (children + children.map(&:all_children)).flatten
      end
    end

    def ramp range, duration, &step
      frame false do
        duration = duration.to_f
        value = range.begin
        distance = (range.end.abs - range.begin.abs).abs.to_f

        loop do
          step.call(value = value.round)
          break if value == range.end

          # step_size must be calculated based on distance remaining because of
          # the rounding errors caused by #round in the previous line
          remaining_distance = distance - (range.begin.abs.to_f - value.abs.to_f).abs.to_f
          remaining_frames = [((duration -= FRAME_DURATION.to_f) * FPS.to_f), 1.0].max
          delta = remaining_distance / remaining_frames
          delta = -delta if range.begin > range.end

          value += delta
          Fiber.yield
        end
      end
    end
  end
end

class Numeric
  def frames
    to_f * Rdmx::Animation::FRAME_DURATION
  end
end
