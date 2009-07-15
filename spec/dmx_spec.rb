require File.dirname(__FILE__)+'/spec_helper'

describe Rdmx::Dmx do
  describe "initialization" do
    it "should initialize a serial port object on the given device" do
      SerialPort.should_receive(:new).with('/tmp/test',
        {'baud' => 250000, 'data_bits' => 8, 'stop_bits' => 2, 'parity' => SerialPort::NONE})
      Rdmx::Dmx.new('/tmp/test')
    end
  end

  describe "packet construction" do
    it "should pad correctly" do
      Rdmx::Dmx.packetize(1).should == ["\x7E","\x06", "\x02", "\x00", "\x00", "\x01", "\xE7"]
    end

    it "should work with byte arguments" do
      lambda do
        Rdmx::Dmx.packetize("\x00")
      end.should_not raise_error
    end

    it "should work with integer arguments" do
      lambda do
        Rdmx::Dmx.packetize(0)
      end.should_not raise_error
    end
  end

  describe "with a dmx port" do
    before :each do
      @dmx = Rdmx::Dmx.new '/tmp/test'
    end

    describe "writing" do
      it "should convert to a packet and write to the port" do
        @port.should_receive(:write).with("\x7E\x06\x03\x00\x00\x01\x02\xE7")
        @dmx.write(1, 2)
      end
    end
  end
end
