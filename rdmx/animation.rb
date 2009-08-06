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
      @storyboard_old_method_missing = somm = storyboard_receiver.method(:method_missing)
      dsl = self
      storyboard_metaclass.send :define_method, :method_missing do |m, *a, &b|
        if dsl.respond_to?(m)
          dsl.send m, *a, &b
        else
          somm.call m, *a, &b
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
  end
end

class Range
  # Breaks a range over a number of steps equal to the number of animation
  # frames contained in the specified seconds. To avoid rounding errors, the
  # values are yielded as Rational numbers, rather than as integers or floats.
  # It differs from #step in that:
  # * the beginning and end of the range are guarranteed to be returned, even
  #   if the size of the steps needs to be munged
  # * the argument is in seconds, rather than the size of the steps
  # * it works on descending and negative ranges as well
  #
  #  (0..10).over(1).to_a # => [0, (5/27), (10/27), (5/9), (20/27)... (10/1)]
  #  (20..0).over(0.1).to_a # => [20, (140/9), (100/9), (20/3), (20/9), (0/1)]
  def over seconds
    total_frames = seconds * Rdmx::Animation::FPS
    start = min || self.begin
    finish = max || self.end
    value = start
    distance = (finish - start).abs

    Enumerator.new do |yielder|
      frame = 0
      loop do
        yielder.yield value
        frame += 1
        break if value == finish # this is a post-conditional loop

        remaining_distance = distance - (start - value).abs
        delta = Rational(remaining_distance, [(total_frames - frame), 1].max)
        delta = -delta if start > finish
        value += delta
      end
    end
  end
end

# Extensions for Numeric that assume the number operated upon is in seconds.
class Numeric
  def frames
    to_f * Rdmx::Animation::FRAME_DURATION
  end
  alias_method :frame, :frames

  def minutes
    self * 60
  end
  alias_method :minute, :minutes

  def seconds
    self
  end
  alias_method :second, :seconds

  def milliseconds
    to_f / 1000.0
  end
  alias_method :ms, :milliseconds
end
