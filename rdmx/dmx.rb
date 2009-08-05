require 'serialport'

module Rdmx
  class Dmx
    attr_accessor :port, :device_name
    DEFAULT_PARAMS = {
      'baud' => 230_400,
      'data_bits' => 8,
      'stop_bits' => 2,
      'parity' => SerialPort::NONE
    }

    def initialize port
      self.device_name = port
      self.port = SerialPort.new device_name, DEFAULT_PARAMS
    end

    def write *data
      @port.write self.class.packetize(*data.flatten).join
    end

    def read
      self.class.depacketize @port.read
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

      def depacketize string
        string.bytes.to_a[5..-2]
      end
    end
  end
end
