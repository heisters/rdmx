module Rdmx
  class Animation
    attr_accessor :universe, :storyboard

    def initialize universe, &storyboard
      self.universe, self.storyboard = universe, storyboard
    end

    def go!
      instance_eval &storyboard
    end

    def ramp range, duration, &step
      frames = duration * universe.fps
      step_size = (range.end - range.begin).abs.to_f / frames.to_f
      frames.times do |frame|
        value = range.begin < range.end ? (step_size * frame).ceil : (range.begin - (step_size * frame)).floor
        step[value]
        sleep duration.to_f / universe.fps.to_f
      end
    end
  end
end
