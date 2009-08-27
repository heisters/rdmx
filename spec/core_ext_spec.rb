require File.dirname(__FILE__)+'/spec_helper'

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
      a.should have(2700).items
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
