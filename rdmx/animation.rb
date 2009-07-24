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
      value = range.begin
      duration = duration.to_f
      number_of_steps = duration * FPS.to_f
      step_duration = duration / number_of_steps
      distance = (range.end.abs - range.begin.abs).abs.to_f

      loop do
        step.call(value = value.round)
        break if value == range.end

        # step_size must be calculated based on distance remaining because of
        # the rounding errors caused by #round in the previous line
        remaining_distance = distance - (range.begin.abs.to_f - value.abs.to_f).abs.to_f
        remaining_frames = [((duration -= step_duration.to_f) * FPS.to_f), 1.0].max
        step_size = remaining_distance / remaining_frames

        step_delta = range.begin < range.end ? step_size : -step_size
        value += step_delta

        sleep step_duration
      end
    end
  end
end
