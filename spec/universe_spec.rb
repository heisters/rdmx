require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Universe do
  def expect_write_with data
    packet = Rdmx::Dmx.packetize(*data.flatten).join
    @port.should_receive(:write).once.with(packet)
  end

  describe "initialization" do
    it "should create a DMX device" do
      Rdmx::Dmx.should_receive(:new).with('/tmp/test').and_return(stub('Dmx', :write => nil))
      Rdmx::Universe.new('/tmp/test')
    end

    it "should initialize the state of the universe" do
      expect_write_with [0] * Rdmx::Universe::NUM_CHANNELS
      Rdmx::Universe.new('/tmp/test')
    end
  end

  describe "with a dmx universe" do
    before :each do
      @universe = Rdmx::Universe.new('/tmp/test')
    end

    describe "controlling" do
      describe "values" do
        describe "all" do
          it "should write a simple value to every channel" do
            expect_write_with [1] * Rdmx::Universe::NUM_CHANNELS
            @universe[0..-1] = 1
          end

          it "should write an incomplete set of values repeatedly" do
            expect_write_with [1,2] * (Rdmx::Universe::NUM_CHANNELS / 2)
            @universe[0..-1] = 1, 2
          end
        end

        describe "one" do
          it "should pad the beginning of the message" do
            expect_write_with [0, 0, 255]
            @universe[2] = 255
          end

          it "should use old values for padding" do
            expect_write_with [1] * Rdmx::Universe::NUM_CHANNELS
            @universe[0..-1] = 1
            expect_write_with(([1] * 10) + [255])
            @universe[10] = 255
          end
        end
      end
    end
  end
end
