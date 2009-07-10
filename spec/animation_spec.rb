require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Animation do
  before :each do
    @fixture_class = Class.new(Rdmx::Fixture) do
      self.channels = :x, :y
    end
    @universe = Rdmx::Universe.new '/tmp/test', @fixture_class
  end

  describe "a simple blink" do
    before :each do
      @blink = Rdmx::Animation.new do
        5.times do
          @universe[0..-1] = 0; sleep 1
          @universe[0..-1] = 255; sleep 1
        end
      end
    end

    it "should run the code 5 times" do
      self.should_receive(:sleep).exactly(10).times.with(1)
      @blink.go
    end
  end
end
