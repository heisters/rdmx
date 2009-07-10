require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Fixture do
  before :each do
    @universe = ['red value', 'green value', 'blue value']

    @class = Class.new(Rdmx::Fixture) do
      self.channels = :red, :green, :blue
    end

  end

  describe "with an instance" do
    before :each do
      @fixture = @class.new @universe, 0, 1, 2
    end

    it "should have accessors for each channel" do
      @fixture.red.should == 'red value'
      @fixture.green.should == 'green value'
      @fixture.blue.should == 'blue value'
      @fixture.red = 0
      @fixture.green = 1
      @fixture.blue = 2
      @fixture.red.should == 0
      @fixture.green.should == 1
      @fixture.blue.should == 2
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
