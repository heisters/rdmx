module Rdmx
  class Animation
    attr_accessor :storyboard


    FPS = Rdmx::Dmx::DEFAULT_PARAMS['baud'] / (8 * (Rdmx::Universe::NUM_CHANNELS + 6))

    def initialize &storyboard
      self.storyboard = storyboard
    end

    def go!
      instance_eval &storyboard
    end

    def ramp range, duration, &step
      frames = duration * FPS
      step_size = (range.end - range.begin).abs.to_f / frames.to_f
      frames.times do |frame|
        value = range.begin < range.end ? (step_size * frame).ceil : (range.begin - (step_size * frame)).floor
        step[value]
        sleep duration.to_f / FPS.to_f
      end
    end
  end
end
