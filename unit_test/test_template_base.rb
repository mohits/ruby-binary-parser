# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'
    
    class TemplateBaseTest < Test::Unit::TestCase
      
      class TestingTemplate < TemplateBase
        def_structure do
          data :number, UInt,   7
          data :flag,   Flag,   1
          data :bytes,  Binary, 32
        end
      end

      def test_initialize_FROM_ABSTRACT_BINARY
        bin_seq = [0b10000001, 0x41, 0x42, 0x43, 0x44]
        t = TestingTemplate.new(AbstractBinary.new(bin_seq.pack("C*")))
        
        assert_equal(0b1000000, t.number.to_i)
        assert(t.flag.on?)
        assert_equal("ABCD", t.bytes.to_s)
      end

      def test_initialize_FROM_BINARY_STRING
        bin_seq = [0b10000001, 0x41, 0x42, 0x43, 0x44]
        t = TestingTemplate.new(bin_seq.pack("C*"))
        
        assert_equal(0b1000000, t.number.to_i)
        assert(t.flag.on?)
        assert_equal("ABCD", t.bytes.to_s)
      end
        
      def test_to_char
        bin_seq = [0x01, 0x02, 0x3, 0x04, 0x05]
        t = gen(*bin_seq)
        
        assert_equal(bin_seq, t.to_chars)
      end

      def test_binary_bit_length
        t = gen(0x01, 0x02, 0x3, 0x04, 0x05, 0x06)
        assert_equal(6 * 8, t.binary_bit_length)
      end

      def test_structure_bit_length
        t = gen(0x01, 0x02, 0x3, 0x04, 0x05, 0x06)
        assert_equal(40, t.structure_bit_length)
      end

      def test_data_method_block_call
        t = gen(0b10000001, 0, 0, 0, 0)

        assert_equal(0b1000000, t.number.to_i)
        assert_equal(0b1000000, t.number{ to_i })
        t.number do |n|
          assert_equal(0b1000000, n.to_i)
        end
      end

      # helper for generating binary
      def gen(*chars)
        return TestingTemplate.new(chars.pack("C*"))
      end
    end
  end
end
