module BinaryParser
  class BufferedStream
    require 'stringio'

    def initialize(stream, buffer_size)
      @stream, @buffer_size = stream, buffer_size
    end

    def read(length)
      if !@buffer || @buffer.eof?
        return nil unless next_buffer = @stream.read(@buffer_size)
        @buffer = StringIO.new(next_buffer)
      end
      return @buffer.read(length)
    end

    def close
      @stream.close
    end
  end
end
