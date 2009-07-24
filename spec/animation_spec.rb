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
      universe = @universe # closure
      @blink = Rdmx::Animation.new do
        5.times do
          universe[0..-1] = 0; sleep 1
          universe[0..-1] = 255; sleep 1
        end
      end
    end

    it "should run the code 5 times" do
      @blink.should_receive(:sleep).exactly(10).times.with(1)
      @blink.go!
    end
  end

  describe "a simple ramp" do
    before :each do
      universe = @universe # closure
      @fade = Rdmx::Animation.new do
        ramp 0..120, 10 do |value|
          universe.fixtures[0..1].each{|f|f.all = value}
        end
      end
      @fade.stub!(:sleep)
    end

    it "should reset all fixtures to 0" do
      @universe.fixtures[0..1].each do |f|
        f.stub!(:all=)
        f.should_receive(:all=).once.with(0)
      end
      @fade.go!
    end

    it "should execute the block based on the duration and the framerate" do
      @universe.fixtures[0..1].each do |f|
        f.should_receive(:all=).exactly(10 * Rdmx::Animation::FPS).times
      end
      @fade.go!
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[120, 120], [120, 120]]
    end
  end

  describe "a negative ramp" do
    before :each do
      universe = @universe # closure
      @fade = Rdmx::Animation.new do
        ramp 120..0, 10 do |value|
          universe.fixtures[0..1].each{|f|f.all = value}
        end
      end
      @fade.stub!(:sleep)
    end

    it "should set all fixtures to 120" do
      @universe.fixtures[0..1].each do |f|
        f.stub!(:all=)
        f.should_receive(:all=).once.with(120)
      end
      @fade.go!
    end

    it "should execute the block based on the duration and the framerate" do
      @universe.fixtures[0..1].each do |f|
        f.should_receive(:all=).exactly(10 * Rdmx::Animation::FPS).times
      end
      @fade.go!
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[0, 0], [0, 0]]
    end
  end

  describe "a float duration ramp" do
    before :each do
      universe = @universe # closure
      @fade = Rdmx::Animation.new do
        ramp 0..255, 0.5 do |value|
          universe.fixtures[0..1].each{|f|f.all = value}
        end
      end
      @fade.stub!(:sleep)
    end

    it "should not throw an error" do
      lambda do
        @fade.go!
      end.should_not raise_error
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[255, 255], [255, 255]]
    end
  end
end
