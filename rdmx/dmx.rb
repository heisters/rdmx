require 'serialport'

module Rdmx
  class Dmx
    attr_accessor :port

    def initialize port
      self.port = SerialPort.new port,
        'baud' => 57600,
        'data_bits' => 8,
        'stop_bits' => 2,
        'parity' => SerialPort::NONE
    end

    def write *data
      @port.write self.class.packetize(*data.flatten).join
    end

    class << self
      def packetize *data
        size = data.size + 1 # add one for the start code
        packet = []
        packet << "\x7E" # start of message
        packet << "\x06" # output only send dmx label
        packet << (size & 255).chr
        packet << ((size >> 8) & 255).chr
        packet << "\x00" # start code
        packet += data.map{|d|d.respond_to?(:chr) ? d.chr : d}
        packet << "\xE7"
      end
    end
  end
end
