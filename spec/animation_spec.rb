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
      @blink = Rdmx::Animation.new @universe do
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

  describe "a ramp with a start point" do
    before :each do
      @fade = Rdmx::Animation.new @universe do
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
        f.should_receive(:all=).exactly(10 * @universe.fps).times
      end
      @fade.go!
    end

    it "should end with all fixtures at end" do
      @fade.go!
      @universe.fixtures[0..1].map{|f|f.all}.should == [[120, 120], [120, 120]]
    end
  end

  describe "a ramp with a start point" do
    it "should move slower on channels that are already part-way there"
  end
end
