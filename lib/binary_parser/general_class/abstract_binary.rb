module BinaryParser
  class AbstractBinary

    attr_reader :bit_length

    def initialize(binary_string, bit_index=nil, bit_length=nil)
      @bin_str = binary_string
      @bit_index = bit_index || 0
      @bit_length = bit_length || binary_string.length * 8 - @bit_index
    end

    def sub(spec)
      new_bit_index, new_bit_length = decode_spec(spec)
      check_invalid_sub_position(new_bit_index, new_bit_length)
      return self.class.new(@bin_str, new_bit_index, new_bit_length)
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
      check_non_byte_position(@bit_index, @bit_length)
      return @bin_str[@bit_index / 8, @bit_length / 8].unpack("C*")
    end

    def to_s
      check_non_byte_position(@bit_index, @bit_length)
      return @bin_str[@bit_index / 8, @bit_length / 8]
    end

    def byte_position?
      @bit_index % 8 == 0 && @bit_length % 8 == 0
    end


    # Methods for generating modified binary.
    def alt(binary_or_uint)
      case binary_or_uint
      when Integer
        alt_uint(binary_or_uint)
      when String
        alt_binary(binary_or_uint)
      else
        raise BadManipulationError, "Argument shouled be Integer or binary-encoded String."
      end
    end
    
    def alt_uint(uint)
      unless uint.is_a?(Integer) && uint >= 0
        raise BadManipulationError, "Specified arg #{uint} is not number of unsigned int."
      end
      unless uint < 2 ** @bit_length
        raise BadBinaryManipulationError, "Specified arg #{uint} is too big to " +
          "express by #{@bit_length} bit."
      end
      alt_binary = BinaryManipulateFunction.convert_uint_into_binary(uint, @bit_length)
      alt_shift = 7 - ((@bit_length - 1) % 8)
      return self.class.new(alt_binary, alt_shift)
    end

    def alt_binary(binary)
      unless binary.length * 8 == @bit_length
        raise BadBinaryManipulationError, "Given binary'length doesn't match self."
      end
      return self.class.new(binary)
    end

    def naive_concat(other)
      left_shift = 7 - ((self.bit_length - 1) % 8)
      left_binary  = BinaryManipulateFunction.convert_uint_into_binary(self.to_i, self.bit_length)
      
      right_shift = 7 - ((other.bit_length - 1) % 8)
      right_binary = BinaryManipulateFunction.convert_uint_into_binary(other.to_i << right_shift,
                                                                       other.bit_length)

      return self.class.new(left_binary + right_binary,
                            left_shift,
                            self.bit_length + other.bit_length)
    end

    def binary_concat(other)
      self.class.new(self.to_s + other.to_s)
    end

    def +(other)
      if self.byte_position? && other.byte_position?
        binary_concat(other) 
      else
        naive_concat(other)
      end
    end


    # Sub methods (helpers)

    def decode_spec(spec)
      new_bit_index  = @bit_index + spec[:bit_index].to_i + spec[:byte_index].to_i * 8
      
      if !spec[:bit_length] && !spec[:byte_length]
        new_bit_length = @bit_length - (new_bit_index - @bit_index)
      else
        new_bit_length = spec[:bit_length].to_i + spec[:byte_length].to_i * 8
      end
      
      return new_bit_index, new_bit_length
    end
      
    def check_invalid_sub_position(new_bit_index, new_bit_length)
      if new_bit_length < 0
        raise BadBinaryManipulationError, "Specified new bit length is negative (#{new_bit_length})."
      end
      unless @bit_index <= new_bit_index && new_bit_index + new_bit_length <= @bit_index + @bit_length
        raise BadBinaryManipulationError, "Specified new bit index #{new_bit_index} is " +
          "out of current binary bit_index=#{@bit_index}, bit_length=#{@bit_length}."
      end
    end

    def check_non_byte_position(bit_index, bit_length)
      unless bit_index % 8 == 0 && bit_length % 8 == 0
        raise BadBinaryManipulationError, "Position {bit_index=#{bit_index}, " +
          "bit_length=#{bit_length}} is not byte-position."
      end
    end
  end
end
