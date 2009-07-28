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
          frame{@universe[0..-1] = 0}
          frame{@universe[0..-1] = 255}
        end
      end
      @blink.stub!(:sleep)
    end

    it "should run the code 5 times" do
      @universe.should_receive(:[]=).exactly(10).times
      @blink.go!
    end

    it "should take 10 frames of time" do
      @blink.should_receive(:sleep).exactly(10).times.with(Rdmx::Animation::FRAME_DURATION)
      @blink.go!
    end

    it "should run things in the sequence expected" do
      10.times do
        @universe.should_receive(:[]=).exactly(1).times
        @blink.should_receive(:sleep).exactly(1).times
        @blink.go_once!
      end
    end
  end

  describe "a simple ramp" do
    before :each do
      @fade = Rdmx::Animation.new do
        ramp 0..120, 10 do |value|
          @universe.fixtures[0..1].each{|f|f.all = value}
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

  describe "a non-inclusive ramp" do
    before :each do
      @fade = Rdmx::Animation.new do
        ramp 0...120, 10 do |value|
          @universe.fixtures[0..1].each{|f|f.all = value}
        end
      end
      @fade.stub!(:sleep)
    end

    it "should end with all fixtures one before end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[119, 119], [119, 119]]
    end
  end

  describe "a negative ramp" do
    before :each do
      @fade = Rdmx::Animation.new do
        ramp 120..0, 10 do |value|
          @universe.fixtures[0..1].each{|f|f.all = value}
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
      @fade = Rdmx::Animation.new do
        ramp 0..255, 0.5 do |value|
          @universe.fixtures[0..1].each{|f|f.all = value}
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

  describe "simultaneous animations" do
    before :each do
      @fixture = @universe.fixtures.first
      @xfade = Rdmx::Animation.new do
        frame do
          ramp 0..255, 4.frames do |value|
            @fixture.x = value
          end
          ramp 255..0, 4.frames do |value|
            @fixture.y = value
          end
        end
      end
      @xfade.stub!(:sleep)
    end

    it "should run the ramps simultaneously in order" do
      @port.should_receive(:write).exactly(2).times
      @fixture.x.should == 0
      @fixture.y.should == 0
      @xfade.go_once!
      @fixture.x.should == 0
      @fixture.y.should == 255
      @xfade.go_once!
      @fixture.x.should == 85
      @fixture.y.should == 170
      @xfade.go_once!
      @fixture.x.should == 170
      @fixture.y.should == 85
      @xfade.go_once!
      @fixture.x.should == 255
      @fixture.y.should == 0
    end

    it "should be 4 frames" do
      @fixture.should_receive(:x=).exactly(4).times
      @fixture.should_receive(:y=).exactly(4).times
      @xfade.go!
    end

    it "should end with all fixtures at end" do
      @xfade.go!
      @fixture.x.should == 255
      @fixture.y.should == 0
    end
  end
end
