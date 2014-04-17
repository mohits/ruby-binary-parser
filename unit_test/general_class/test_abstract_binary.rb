# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class AbstractBinaryTest < Test::Unit::TestCase
      
      def test_to_i
        abin = AbstractBinary.new(gen_bin(0b10101010, 0b01010101))
        assert_equal(0b1010101001010101, abin.to_i)
      end

      def test_to_chars
        abin = AbstractBinary.new(gen_bin(0b10101010, 0b01010101))
        assert_equal(0b10101010, abin.to_chars[0])
        assert_equal(0b01010101, abin.to_chars[1])
      end

      def test_to_s
        abin = AbstractBinary.new(gen_bin(0x48, 0x4f, 0x47, 0x45))
        assert_equal("HOGE", abin.to_s)
      end

        def test_sub
        abin = AbstractBinary.new(gen_bin(0b11110000, 0b11110000, 0b11110001))
        assert_equal(0b110, abin.sub(:bit_index => 2, :bit_length => 3).to_i)
        assert_equal([0b11110000, 0b11110001], abin.sub(:bit_index => 6).sub(:bit_index => 2).to_chars)
      end

      def test_to_chars_error
        abin = AbstractBinary.new(gen_bin(0b11110000, 0b11111111))
        sub = abin.sub(:bit_index => 4, :bit_length => 8)
        assert_equal(0b00001111, sub.to_i)
        assert_raise(BadBinaryManipulationError) do
          sub.to_chars
        end
      end

      def test_sub_error
        abin = AbstractBinary.new(gen_bin(0b11110000, 0b11111111))
        assert_raise(BadBinaryManipulationError) do
          abin.sub(:bit_index => 17)
        end
        assert_raise(BadBinaryManipulationError) do
          abin.sub(:bit_length => 17)
        end
      end

      def test_alt_binary
        abin = AbstractBinary.new(gen_bin(0b00000000), 0, 8)
        assert_equal(0,   abin.to_i)
        assert_equal(255, abin.alt([0b11111111].pack("C*")).to_i)
      end

      def test_alt_uint
        abin = AbstractBinary.new(gen_bin(0b00000000), 1, 3)
        assert_equal(0, abin.to_i)
        assert_equal(2, abin.alt(2).to_i)
      end
      
      def test_naive_concat_CASE1
        abin1 = AbstractBinary.new(gen_bin(0b11110000, 0b11110000), 3, 7)
        assert_equal(0b1000011, abin1.to_i)

        abin2 = AbstractBinary.new(gen_bin(0b11110000, 0b11110000), 7, 3)
        assert_equal(0b011, abin2.to_i)

        con_abin = abin1.naive_concat(abin2)
        assert_equal(0b1000011011, con_abin.to_i)
        assert_equal(10, con_abin.bit_length)
      end
        
      def test_naive_concat_CASE2
        abin1 = AbstractBinary.new(gen_bin(0b00000000, 0b00001111), 2, 14)
        assert_equal(0b00000000001111, abin1.to_i)

        abin2 = AbstractBinary.new(gen_bin(0b11110000), 0, 1)
        assert_equal(0b1, abin2.to_i)

        con_abin = abin1.naive_concat(abin2)
        assert_equal(0b000000000011111, con_abin.to_i)
        assert_equal(15, con_abin.bit_length)
      end

      def test_binary_concat_CASE1
        abin1 = AbstractBinary.new(gen_bin(0b10000000), 0, 8)
        abin2 = AbstractBinary.new(gen_bin(0b00000000), 0, 8)

        con_abin = abin1.binary_concat(abin2)
        assert_equal(0b1000000000000000, con_abin.to_i)
        assert_equal(16, con_abin.bit_length)
      end

      # helper for generating binary
        def gen_bin(*chars)
        return chars.pack("C*")
      end
    end
  end
end
