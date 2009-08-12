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

    it "should setup an empty set of fixtures" do
      u = Rdmx::Universe.new('/tmp/test')
      u.should have(Rdmx::Universe::NUM_CHANNELS).fixtures
      u.fixtures.compact.should be_empty
    end

    describe "with fixtures" do
      before :each do
        @fixture_class = Class.new(Rdmx::Fixture) do
          self.channels = :x, :y
        end
      end

      it "should setup a full set of fixtures if provided" do
        u = Rdmx::Universe.new('/tmp/test', @fixture_class)
        u.should have(Rdmx::Universe::NUM_CHANNELS / 2).fixtures
      end

      it "should make it possible to limit the number of fixtures" do
        u = Rdmx::Universe.new('/tmp/test', @fixture_class => 10)
        u.should have(10).fixtures
      end
    end
  end

  describe "with a dmx universe" do
    before :each do
      @universe = Rdmx::Universe.new('/tmp/test')
    end

    it "should have a custom inspect" do
      @universe.inspect.should == "#<Rdmx::Universe:/tmp/test [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]>"
    end

    describe "controlling" do
      it "should buffer writes and only write once" do
        packet = Rdmx::Dmx.packetize(*([1, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 2)))).join
        @port.should_receive(:write).once.with(packet)
        packet = Rdmx::Dmx.packetize(*([1] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 1)))).join
        @port.should_not_receive(:write).with(packet)

        @universe.buffer do
          @universe[0] = 1
          @universe[1] = 255
        end
      end

      it "should globaly buffer writes and only write once" do
        packet = Rdmx::Dmx.packetize(*([1, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 2)))).join
        @port.should_receive(:write).once.with(packet)
        packet = Rdmx::Dmx.packetize(*([1] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 1)))).join
        @port.should_not_receive(:write).with(packet)
        universe2 = Rdmx::Universe.new('/tmp/test')
        universe2.stub!(:flush_buffer!)
        universe2.class.buffer do
          @universe[0] = 1
          @universe[1] = 255
        end
      end

      it "should not flush the buffer prematurely on nested buffers" do
        packet = Rdmx::Dmx.packetize(*([1, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 2)))).join
        @port.should_receive(:write).once.with(packet)
        packet = Rdmx::Dmx.packetize(*([1] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 1)))).join
        @port.should_not_receive(:write).with(packet)

        @universe.buffer do
          @universe.buffer do
            @universe[0] = 1
          end
          @universe[1] = 255
        end
      end

      it "should not ensure write on an exception" do
        block = lambda{}
        block.should_receive(:call).and_raise(Interrupt)
        @universe.should_receive(:buffer_off!)
        @universe.should_not_receive(:flush_buffer!)
        lambda do
          @universe.buffer &block
        end.should raise_error(Interrupt)
      end

      it "should not ensure write on an exception at the class level" do
        block = lambda{}
        block.should_receive(:call).and_raise(Interrupt)
        @universe.should_receive(:buffer_off!)
        @universe.should_not_receive(:flush_buffer!)
        lambda do
          @universe.class.buffer &block
        end.should raise_error(Interrupt)
      end

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
            expect_write_with([0, 0, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 3)))
            @universe[2] = 255
          end

          it "should use old values for padding" do
            expect_write_with [1] * Rdmx::Universe::NUM_CHANNELS
            @universe[0..-1] = 1
            expect_write_with(([1] * 10) + [255] + ([1] * (Rdmx::Universe::NUM_CHANNELS - 11)))
            @universe[10] = 255
          end
        end

        describe "patterns" do
          it "should pad the beginning of the message and repeat the pattern" do
            expect_write_with [0, 0, 128, 255, 128, 255] + ([0] * (Rdmx::Universe::NUM_CHANNELS - 6))
            @universe[2..5] = 128, 255
          end
        end
      end
    end

    describe "fixtures" do
      before :each do
        @fixture_class = Class.new(Rdmx::Fixture) do
          self.channels = :x, :y
        end
        @universe.fixtures.replace @fixture_class
      end

      it "should be possible to fill the universe with fixtures" do
        @universe.should have(Rdmx::Universe::NUM_CHANNELS / 2).fixtures
      end

      it "should correctly assign all the addresses" do
        @universe.fixtures.map{|f|f.channels.values}.flatten.should == (0...512).to_a
      end
    end
  end
end
