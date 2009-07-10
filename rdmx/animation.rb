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
      frames.times do |frame|
        step[(((range.last - range.first).to_f / frames.to_f) * frame).ceil]
        sleep duration.to_f / universe.fps.to_f
      end
    end
  end
end
