# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/general_class/abstract_binary.rb'

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
          abin.sub(:bit_index => 16)
        end
        assert_raise(BadBinaryManipulationError) do
          abin.sub(:bit_length => 17)
        end
      end

      # helper for generating binary
      def gen_bin(*chars)
        return chars.pack("C*")
      end
    end
  end
end
