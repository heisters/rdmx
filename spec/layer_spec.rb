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
    @layers[0][0..-1] = 255, 0, 0
    @layers.apply!
    @universe.values.should == (([255, 0, 0] * (Rdmx::Universe::NUM_CHANNELS / 3)) + [0, 0])
  end

  it "should be easy to create a blend" do
    @layers[0][0..-1] = 255, 0, 0
    @layers[1][0..-1] = 0, 255, 0
    @layers.apply!
    @universe.values.should == (([255, 255, 0] * (Rdmx::Universe::NUM_CHANNELS / 3)) + [0, 0])
  end

  it "will not blend higher than 255" do
    @layers[0][0] = 255
    @layers[1][0] = 1
    @layers.apply!
    @universe.values[0].should == 255
  end

  it "will not blend lower than 0" do
    @layers[0][0] = 1
    @layers[1][0] = -3
    @layers.apply!
    @universe.values[0].should == 0
  end
end
