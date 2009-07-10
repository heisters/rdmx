require File.dirname(__FILE__)+'/../rdmx'

Spec::Runner.configure do |config|
  config.before :each do
    @port = stub('SerialPort', :write => nil)
    SerialPort.stub!(:new).and_return(@port)
  end
end
