$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class BinaryManipulateFunctionTest < Test::Unit::TestCase
      
      def test_needed_sub_string
        str = gen_bin(0, 0, 0)

        assert_equal([str[0],    0,  0], nss(str,  0, 7))
        assert_equal([str[0],    1,  2], nss(str,  1, 5))
        assert_equal([str[0..1], 1,  7], nss(str,  1, 8))
        assert_equal([str[0..2], 1,  3], nss(str,  1, 20))
        assert_equal([str[1..2], 2,  3], nss(str, 10, 20))
        assert_equal([str[1],    0,  0], nss(str,  8, 15))
      end

      def test_to_unsigned_int
        str = gen_bin(0b11110000, 0b11110000)

        assert_equal(0b01,               tui(str, 7, 7))
        assert_equal(0b00001111,         tui(str, 4, 4))
        assert_equal(0b1111000011110000, tui(str, 0, 0))
      end

      # helper for generating binary
      def gen_bin(*chars)
        return chars.pack("C*")
      end

      def nss(*args)
        BinaryManipulateFunction.needed_sub_string(*args)
      end

      def tui(*args)
        BinaryManipulateFunction.to_unsigned_int(*args)
      end
    end
  end
end
