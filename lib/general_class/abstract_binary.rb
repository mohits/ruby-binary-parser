module BinaryParser
  class AbstractBinary

    attr_reader :bit_length

    def initialize(binary_string, bit_index=nil, bit_length=nil)
      unless binary_string.encoding == Encoding::BINARY
        raise BadBinaryManipulationError, "binary_string's encoding should be" +
          "ASCII_8BIT(BINARY). This is #{binary_string.encoding}."
      end
      @bin_str = binary_string
      @bit_index = bit_index || 0
      @bit_length = bit_length || binary_string.length * 8
    end

    def sub(spec)
      additional_bit_index = spec[:bit_index].to_i + spec[:byte_index].to_i * 8
      if additional_bit_index >= @bit_index + @bit_length
        raise BadBinaryManipulationError, "Impossible index specification of sub binary " +
          "(bit_index: #{additional_bit_index} on [#{@bit_index}, #{@bit_length}))"
      end

      if spec[:bit_length] || spec[:byte_length]
        new_bit_length = spec[:bit_length].to_i + spec[:byte_length].to_i * 8
      else
        new_bit_length = @bit_length - additional_bit_index
      end
      if additional_bit_index + new_bit_length > @bit_length
        raise BadBinaryManipulationError, "Impossible length specification of" +
          "sub binary (bit_index: #{additional_bit_index}, " +
          "bit_length: #{new_bit_length} on [#{@bit_index}, #{@bit_length}])"
      end

      return self.class.new(@bin_str, @bit_index + additional_bit_index, new_bit_length)
    end

    def to_i
      if @bit_length == 0
        raise BadBinaryManipulationError, "Cannot convert empty binary into integer."
      end
      str, ml, mr = BinaryManipulateFunction.needed_sub_string(@bin_str, 
                                                               @bit_index,
                                                               @bit_index + @bit_length - 1)
      return BinaryManipulateFunction.to_unsigned_int(str, ml, mr)
    end
    
    def to_chars
      unless @bit_index % 8 == 0 && @bit_length % 8 == 0
        raise BadBinaryManipulationError, "Invalid position(from #{@bit_index} bit)" +
          "and length(#{@bit_length} bit)."
      end
      return @bin_str[@bit_index / 8, @bit_length / 8].unpack("C*")
    end

    def to_s
      unless @bit_index % 8 == 0 && @bit_length % 8 == 0
        raise BadBinaryManipulationError, "Invalid position(from #{@bit_index} bit) " +
          "and length(#{@bit_length} bit)."
      end
      return @bin_str[@bit_index / 8, @bit_length / 8]
    end
  end
end
