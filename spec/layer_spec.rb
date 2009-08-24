require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Layers do
  before :each do
    @fixture_class = Class.new(Rdmx::Fixture) do
      self.channels = :r, :g, :b
    end
    @universe = Rdmx::Universe.new '/tmp/test', @fixture_class
    @layers = Rdmx::Layers.new 2, @universe
  end

  it "should be easy to wash the background" do
    @layers[0][true] = 255
    @layers.apply!
    @universe.values.should == [255] * Rdmx::Universe::NUM_CHANNELS
  end

  it "should be easy to create a blend" do
    @layers[0][0] = 10
    @layers[1][0] = 5
    @layers.apply!
    @universe.values.should == [15] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 1))
  end

  it "should not blend higher than 255" do
    @layers[0][0] = 255
    @layers[1][0] = 1
    @layers.apply!
    @universe.values[0].should == 255
  end

  it "should not blend lower than 0" do
    @layers[0][0] = 1
    @layers[1][0] = -3
    @layers.apply!
    @universe.values[0].should == 0
  end

  it "should provide a fixtures interface" do
    @layers[0].fixtures[0].all = 255
    @layers[0].values.to_a.should == [255, 255, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 3))
  end

  it "should be easy to add one new layer" do
    @layers.push
    @layers.should have(3).items
    @layers[0][0] = 1
    @layers[1][0] = 2
    @layers[2][0] = 3
    @layers.apply!
    @universe.values.first.should == 6
  end

  it "should be easy to add n new layers" do
    @layers.push 10
    @layers.should have(12).items
    @layers[0][0] = 1
    @layers[1][0] = 2
    @layers[11][0] = 3
    @layers.apply!
    @universe.values.first.should == 6
  end

  it "should not copy values from the parent universe" do
    @universe[0..-1] = 100
    @layers.push
    @layers.last.values.max.should == 0
  end

  it "should not persist updates" do
    @layers[0][0] = 1
    @layers.apply!
    @layers[0][0] = 0
    @layers[0][1] = 1
    @layers.apply!
    @universe.values[0..1].should == [0, 1]
  end

  describe "with alpha" do
    before :each do
      @layers.compositor = :alpha
    end

    it "blend according to alpha" do
      @layers[0].alpha[true] = 0.75
      @layers[1].alpha[true] = 0.25
      @layers[0][0] = 100
      @layers[1][0] = 100
      @layers.apply!
      @universe.values.first.should == 81
    end

    it "should not blend layers that are behind a 1.0 alpha layer" do
      @layers[0].alpha[true] = 0.75
      @layers[1].alpha[true] = 1.00
      @layers[0][0] = 100
      @layers[1][0] = 100
      @layers.apply!
      @universe.values.first.should == 100
    end

    it "should mask where the layer has no values" do
      @layers[0].alpha[true] = 0.75
      @layers[1].alpha[0] = 1.00
      @layers[0][0..1] = 100
      @layers[1][0] = 100
      @layers.apply!
      @universe.values[0..1].should == [100, 75]
    end
  end

  describe "with last on top" do
    before :each do
      @layers.compositor = :last_on_top
    end

    it "should blend everything normally, except the top" do
      @layers.push
      @layers[0][0..1] = 100
      @layers[1][0..1] = 100
      @layers[2][0] = 100
      @layers.apply!
      @universe.values[0..1].should == [100, 200]
    end
  end
end
