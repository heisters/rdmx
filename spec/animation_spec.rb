require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Animation do
  include Rdmx

  before :each do
    @fixture_class = Class.new(Fixture) do
      self.channels = :x, :y
    end
    @universe = Universe.new '/tmp/test', @fixture_class
  end

  describe "DSL mixin" do
    it "should delegate to DSL methods" do
      klass = Class.new(Animation) do
        def foo; end
      end
      a = klass.new{foo}
      lambda do
        a.go!
      end.should_not raise_error
    end

    it "should delegate to default receiver methods" do
      stub!(:foo)
      a = Animation.new{foo}
      lambda do
        a.go!
      end.should_not raise_error
    end

    it "should not persist the mixed-in DSL" do
      klass = Class.new(Animation) do
        def foo; end
      end
      a = klass.new{foo}
      lambda do
        a.go!
      end.should_not raise_error
      lambda do
        foo
      end.should raise_error
    end
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
      @blink.should_receive(:sleep).exactly(10).times
      @blink.go!
    end

    it "should run things in the sequence expected" do
      10.times do
        @universe.should_receive(:[]=).exactly(1).times
        @blink.should_receive(:sleep).exactly(1).times
        @blink.go_once!
      end
    end

    it "should sleep less time if the animation is slow" do
      t = Time.now
      slow = ((Animation.frame_duration / 1.5) * 100000.0).round / 100000.0
      Time.should_receive(:now).and_return(t, t + slow)
      @blink.should_receive(:sleep).with(Animation.frame_duration - slow)
      @blink.go_once!
    end

    it "should not sleep at all if the animation is really slow" do
      t = Time.now
      slow = ((Animation.frame_duration * 2) * 100000.0).round / 100000.0
      Time.should_receive(:now).and_return(t, t + slow)
      @blink.should_receive(:sleep).with(0)
      @blink.go_once!
    end

    it "should report the elapsed time" do
      t = Time.now
      slow = ((Animation.frame_duration * 2) * 100000.0).round / 100000.0
      Time.should_receive(:now).and_return(t, t + slow)
      @blink.go_once!
      ((@blink.timing.last * 100000.0).round / 100000.0).should == slow
    end

    it "should report a running average of frame elapsed time" do
      t = Time.now
      slow = ((Animation.frame_duration * 2) * 100000.0).round / 100000.0
      Time.should_receive(:now).and_return(*([t, t + slow] * 5))
      5.times{@blink.go_once!}
      ((@blink.timing.average * 100000.0).round / 100000.0).should == slow
      @blink.timing.should have(5).items
    end
  end

  describe "a simple ramp" do
    before :each do
      @fade = Animation.new do
        frame.new do
          (0..120).over(10.seconds).each do |value|
            @universe.fixtures[0..1].each{|f|f.all = value.to_f.round}
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
        f.should_receive(:all=).exactly(10.to_frames).times
      end
      @fade.go!
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[120, 120], [120, 120]]
    end

    it "should run things in the sequence expected" do
      (10.to_frames).times do
        @universe.fixtures[0..1].each{|f|f.should_receive(:all=).exactly(1).times}
        @fade.should_receive(:sleep).exactly(1).times
        @fade.go_once!
      end
    end
  end

  describe "a non-inclusive ramp" do
    before :each do
      @fade = Animation.new do
        (0...120).over(10).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value.to_f.round}
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
          (0..2).over(4).each do |value|
            @universe.fixtures.first.all = value.to_f.round
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
      frames = 4.to_frames
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
        (120..0).over(10).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value.to_f.round}
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
        f.should_receive(:all=).exactly(10.to_frames).times
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
        (0..255).over(0.5).each do |value|
          frame.new do
            @universe.fixtures[0..1].each{|f|f.all = value.to_f.round}
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
          (0..255).over(4.frames).each do |value|
            @fixture.x = value.to_f.round
            continue
          end
        end
        frame.new do
          (255..0).over(4.frames).each do |value|
            @fixture.y = value.to_f.round
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
            (0..255).over(4.frames).each do |value|
              @fixture.x = value.to_f.round
              continue
            end
          end
          frame.new do
            (255..0).over(4.frames).each do |value|
              @fixture.y = value.to_f.round
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
      @xfade.root_frame.should have(1).all_children
      @xfade.go_once! # the other children aren't added until the root is run
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

describe Range do
  describe "over" do
    it "should go from 0 to 9" do
      a = (0...10).over(1.second).to_a
      a.first.should == 0
      a.last.should == 9
    end

    it "should work with a negative range" do
      a = (-2..2).over(1.second).to_a
      a.first.should == -2
      a.last.should == 2
    end

    it "should work with a descending range" do
      a = (2..-2).over(1.second).to_a
      a.first.should == 2
      a.last.should == -2
    end

    it "should be rewindable" do
      pending "Can't figure out how to do this"
      e = (0..10).over(1.second)
      begin
        loop{e.next}
      rescue StopIteration
      end
      lambda do
        e.next.should == 0
      end.should_not raise_error
    end

    it "should work with very small fractional ramps" do
      a = (0.01..0.001).over(100.seconds).to_a
      a.should have(5500).items
    end
  end
end

describe Numeric do
  before :each do
    @num = 10
  end

  it "should convert to frames" do
    @num.frames.should == Rdmx::Animation.frame_duration * 10.0
  end

  it "should convert to minutes" do
    @num.minutes.should == 600
  end

  it "should convert to milliseconds" do
    @num.milliseconds.should == 0.01
  end

  it "should assume everything is in seconds" do
    @num.seconds.should == @num
  end
end
