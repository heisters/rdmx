require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Fixture do
  before :each do
    @class = Class.new(Rdmx::Fixture) do
      self.channels = :red, :green, :blue
    end

    @universe = Rdmx::Universe.new '/tmp/test', @class
  end

  describe "with an instance" do
    before :each do
      @fixture = @class.new @universe, 0, 1, 2
    end

    it "should have accessors for each channel" do
      @fixture.red.should == 0
      @fixture.green.should == 0
      @fixture.blue.should == 0
      @fixture.red = 0
      @fixture.green = 1
      @fixture.blue = 2
      @fixture.red.should == 0
      @fixture.green.should == 1
      @fixture.blue.should == 2
      @universe[0].should == 0
      @universe[1].should == 1
      @universe[2].should == 2
    end

    it "should have an accessor for all channels" do
      @fixture.all.should == [0, 0, 0]
      @fixture.all = 10, 20, 30
      @fixture.all.should == [10, 20, 30]
      @universe[0..2].should == [10, 20, 30]
    end

    it "should raise an error if you try to set all channels without enough values" do
      lambda do
        @fixture.all = 'r', 'g'
      end.should raise_error(ArgumentError)
    end

    it "should apply one value to all channels" do
      @fixture.all = 'foo'
      @fixture.all.should == %w(foo) * 3
    end

    it "should write to the universe" do
      @fixture.all = 100
      @universe[0..2].should == [100, 100, 100]
    end

    it "should have a useful inspect" do
      class ::TestFixture < Rdmx::Fixture
        self.channels = :r, :g, :b
      end
      @fixture = TestFixture.new @universe, 0, 1, 2
      @fixture.inspect.should == "#<TestFixture {:r=>0, :g=>1, :b=>2}>"
    end
  end

  describe "with a layer" do
    before :each do
      @layers = Rdmx::Layers.new 1, @universe
      @layer = @layers.first
      @fixture = @layer.fixtures.first
    end

    it "should provide an alpha accessor if the layer supports it" do
      @fixture.alpha.should == [1.0, 1.0, 1.0]
      @fixture.alpha = 0.5
      @layer.alpha[0..3].to_a.should == [0.5, 0.5, 0.5, 1.0]
      @fixture.alpha = 0.5, 0.75, 0.4
      @layer.alpha[0..3].to_a.should == [0.5, 0.75, 0.4, 1.0]
    end
  end

  describe "color calibration" do
    before :each do
      @class = Class.new(Rdmx::Fixture) do
        self.channels = :red, :green, :blue
        calibrate :red => 1.1, :green => 0.9, :blue => 2
      end

      @universe = Rdmx::Universe.new '/tmp/test', @class
      @fixture = @class.new @universe, 0, 1, 2
    end

    it "should add the calibration to any values" do
      @fixture.all = 50, 60, 70
      @fixture.all.should == [55, 54, 140]
    end
  end

  describe "initializing" do
    it "should raise an error if you don't provide enough addresses" do
      lambda do
        @class.new @universe, 0, 1
      end.should raise_error(ArgumentError)
    end
  end
end
