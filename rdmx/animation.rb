module Rdmx
  class Animation
    attr_accessor :storyboard

    def initialize &storyboard
      self.storyboard = storyboard
    end

    def go
      self.storyboard.call
    end
  end
end
