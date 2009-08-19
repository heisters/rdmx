class Range
  def start
    min || self.begin
  end

  def finish
    max || self.end
  end

  def distance
    (finish - start).abs
  end

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
    total_frames = seconds.to_frames
    value = start

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

class Numeric
  # Assume the current number is frames, and convert it to an equivalent
  # number of seconds.
  def frames
    to_f * Rdmx::Animation.frame_duration
  end
  alias_method :frame, :frames

  # Assume the current number is minutes, and convert it to an equivalent
  # number of seconds.
  def minutes
    self * 60
  end
  alias_method :minute, :minutes

  # Assume the current number is seconds, and convert it to an equivalent
  # number of seconds. Ie. do nothing.
  def seconds
    self
  end
  alias_method :second, :seconds

  # Assume the current number is milliseconds, and convert it to an equivalent
  # number of seconds.
  def milliseconds
    to_f / 1000.0
  end
  alias_method :ms, :milliseconds

  # Assume the current number is seconds, and convert it to an equivalent
  # number of frames.
  def to_frames
    self * Rdmx::Animation.fps
  end
end

class Fifo < Array
  attr_accessor :max_size

  def initialize max_size
    self.max_size = max_size
  end

  def full?
    size == max_size
  end

  def push value
    super value
    shift if size > max_size
  end
end
