require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Animation do
  include Rdmx

  before :each do
    @fixture_class = Class.new(Fixture) do
      self.channels = :x, :y
    end
    @universe = Universe.new '/tmp/test', @fixture_class
  end

  describe "a simple blink" do
    before :each do
      @blink = Animation.new do
        frame.new do
          5.times do
            @universe[0..-1] = 0
            continue
            @universe[0..-1] = 255
            continue
          end
        end
      end
      @blink.stub!(:sleep)
    end

    it "should attach 1 frame to the root frame" do
      @blink.root_frame.should have(1).children
      @blink.root_frame.should have(1).all_children
    end

    it "should run the code 5 times" do
      @universe.should_receive(:[]=).exactly(10).times
      @blink.go!
    end

    it "should take 10 frames of time" do
      @blink.should_receive(:sleep).exactly(10).times.with(Animation::FRAME_DURATION)
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
      @fade = Animation.new do
        frame.new do
          timed_range(0..120, 10).each do |value|
            @universe.fixtures[0..1].each{|f|f.all = value}
            continue
          end
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
        f.should_receive(:all=).exactly(10 * Animation::FPS).times
      end
      @fade.go!
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[120, 120], [120, 120]]
    end

    it "should run things in the sequence expected" do
      (10 * Animation::FPS).times do
        @universe.fixtures[0..1].each{|f|f.should_receive(:all=).exactly(1).times}
        @fade.should_receive(:sleep).exactly(1).times
        @fade.go_once!
      end
    end
  end

  describe "a non-inclusive ramp" do
    before :each do
      @fade = Animation.new do
        timed_range(0...120, 10).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value}
            continue
          end
        end
      end
      @fade.stub!(:sleep)
    end

    it "should end with all fixtures one before end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[119, 119], [119, 119]]
    end
  end

  describe "a ramp with a small range and a larger duration" do
    before :each do
      @fade = Animation.new do
        frame.new do
          timed_range(0..2, 4).each do |value|
            @universe.fixtures.first.all = value
            continue
          end
        end
      end
      @fade.stub!(:sleep)
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures.first.all.should == [2, 2]
    end

    it "should step up evenly" do
      frames = 4 * Animation::FPS
      values = (0..frames).to_a.map do |frame|
        @fade.go_once!
        @universe.fixtures.first.all
      end
      # The distribution is .25, .5, .25 due to rounding
      [
        values.select{|a|a == [0, 0]}.size,
        values.select{|a|a == [1, 1]}.size,
        values.select{|a|a == [2, 2]}.size
      ].should == [(frames / 4), (frames / 2), (frames / 4) + 1]
    end
  end

  describe "a negative ramp" do
    before :each do
      @fade = Animation.new do
        timed_range(120..0, 10).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value}
            continue
          end
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
        f.should_receive(:all=).exactly(10 * Animation::FPS).times
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
      @fade = Animation.new do
        timed_range(0..255, 0.5).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value}
            continue
          end
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
      @xfade = Animation.new do
        frame.new do
          timed_range(0..255, 4.frames).each do |value|
            @fixture.x = value
            continue
          end
        end
        frame.new do
          timed_range(255..0, 4.frames).each do |value|
            @fixture.y = value
            continue
          end
        end
      end
      @xfade.stub!(:sleep)
    end

    it "should have 2 frames on the root" do
      @xfade.root_frame.should have(2).children
      @xfade.root_frame.should have(2).all_children
    end

    it "should run the ramps simultaneously in order" do
      @port.should_receive(:write).exactly(4).times
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

  describe "nested frames" do
    before :each do
      @fixture = @universe.fixtures.first
      @xfade = Animation.new do
        frame.new do
          frame.new do
            timed_range(0..255, 4.frames).each do |value|
              @fixture.x = value
              continue
            end
          end
          frame.new do
            timed_range(255..0, 4.frames).each do |value|
              @fixture.y = value
              continue
            end
          end
        end
      end
      @xfade.stub!(:sleep)
    end

    it "should end with all fixtures at end" do
      @xfade.go!
      @fixture.x.should == 255
      @fixture.y.should == 0
    end

    it "should be 4 frames" do
      @fixture.should_receive(:x=).exactly(4).times
      @fixture.should_receive(:y=).exactly(4).times
      @xfade.should_receive(:sleep).exactly(4).times
      @xfade.go!
    end

    it "should have 1 frame on the root" do
      @xfade.root_frame.should have(1).children
      @xfade.root_frame.should have(3).all_children
    end

    it "should run the ramps simultaneously in order" do
      @port.should_receive(:write).exactly(4).times
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
  end
end
