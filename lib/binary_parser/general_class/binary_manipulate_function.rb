module BinaryParser
  module BinaryManipulateFunction
    extend self

    MASK = [0b11111111,
            0b01111111,
            0b00111111,
            0b00011111,
            0b00001111,
            0b00000111,
            0b00000011,
            0b00000001]

    def needed_sub_string(str, bit_first_pos, bit_last_pos)
      return str[(bit_first_pos / 8)..(bit_last_pos / 8)], bit_first_pos % 8, 7 - (bit_last_pos % 8)
    end

    def needed_sub_string_in_domain_of_definition?(str, bfp, blp)
      bfp < blp && blp / 8 < str.length
    end

    def to_unsigned_int(binary_string, margin_left=0, margin_right=0)
      chars = binary_string.unpack("C*")
      converted = chars.shift & MASK[margin_left]
      chars.each do |char|
        converted = (converted << 8) + char
      end
      return converted >> margin_right
    end

    def to_unsigned_int_in_domain_of_definition?(str, ml, mr)
      [ str.length >= 1,
        0 <= ml && ml <= 7,
        0 <= mr && mr <= 7,
        str.length != 1 || ml + mr <= 7 ].all?
    end

    def convert_uint_into_binary(uint, bit_length)
      if uint == 0
        if bit_length > 0
          convert_uint_into_binary(0, bit_length - 8) + [0].pack("C1")
        else
          [].pack("C0")
        end
      else
        convert_uint_into_binary(uint / 256, bit_length - 8) + [uint % 256].pack("C1")
      end
    end

    def convert_uint_into_binary_in_domain_of_definition?(uint, bit_length)
      bit_length >= 0 && 0 <= uint && uint < 2 ** bit_length
    end
  end
end
