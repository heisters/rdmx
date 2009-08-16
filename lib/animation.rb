require 'fiber'
module Rdmx
  class Animation
    attr_accessor :storyboard, :root_frame
    attr_reader :timing

    class << self
      def default_fps
        Rdmx::Dmx::DEFAULT_PARAMS['baud'] / (8 * (Rdmx::Universe::NUM_CHANNELS + 6))
      end

      def fps
        @fps ||= default_fps
      end

      def fps= new_fps
        @fps = new_fps
      end

      def frame_duration
        1.0 / fps
      end
    end

    public :sleep

    def initialize &storyboard
      self.storyboard = storyboard
      @timing = Timing.new
      self.root_frame = Frame.new do
        # priming
        storyboard.call
        Frame.yield

        # running
        loop do
          start = Time.now
          Rdmx::Universe.buffer do
            root_frame.children.each do |frame|
              frame.resume if frame.alive? || frame.all_children.any?(&:alive?)
            end
          end

          elapsed = Time.now - start
          @timing.push elapsed
          sleep_for = [self.class.frame_duration - elapsed, 0].max

          Frame.yield sleep(sleep_for)
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

    class Timing < ::Fifo
      attr_reader :average

      def initialize # disable initialization arguments
        @sum = 0.0
        super 50
      end

      def push elapsed
        @sum += elapsed
        @sum -= first if full?
        super(elapsed).tap{@average = @sum / size}
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
