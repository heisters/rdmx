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
        Frame.yield

        loop do
          Rdmx::Universe.buffer do
            root_frame.children.each do |frame|
              frame.resume if frame.alive? || frame.all_children.any?(&:alive?)
            end
          end
          Frame.yield sleep(FRAME_DURATION)
          break unless root_frame.all_children.any?(&:alive?)
        end
      end
      go_once! # prime it by setting up the storyboard
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

    class Frame < Fiber
      attr_accessor :parent, :children
      def initialize &block
        super(&block)
        self.children = []
        if Frame.current.respond_to?(:children)
          self.parent = Frame.current
          parent.children << self
        end
      end

      def resume *args
        super(*args) if alive?
        children.each{|c|c.resume(*args) if c.alive?} if parent
      end

      def all_children
        (children + children.map(&:all_children)).flatten
      end
    end

    def frame
      Frame
    end

    def continue
      frame.yield
    end

    def timed_range range, duration
      total_frames = duration * FPS
      start = range.min || range.begin
      finish = range.max || range.end
      value = start
      distance = (finish.abs - start.abs).abs

      Enumerator.new do |yielder|
        frame = 0
        loop do
          yielder.yield value.to_f.round
          frame += 1
          break if value == finish # this is a post-conditional loop

          remaining_distance = distance - (start.abs - value.abs).abs
          delta = Rational(remaining_distance, [(total_frames - frame), 1].max)
          delta = -delta if start > finish
          value += delta
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
