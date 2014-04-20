# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'
    
    class UIntTemplateTest < Test::Unit::TestCase
      
      class TestingTemplate < TemplateBase
        def_structure do
          data :n1, UInt, 8
          data :n2, UInt, 8
          data :n3, UInt, 8
        end
      end

      def test_bit_access
        t = gen(1, 2, 4)
        
        assert_equal(1, t.n1[0])
        assert_equal(0, t.n1[1])
        assert_equal(0, t.n1[2])

        assert_equal(0, t.n2[0])
        assert_equal(1, t.n2[1])
        assert_equal(0, t.n2[2])

        assert_equal(0, t.n3[0])
        assert_equal(0, t.n3[1])
        assert_equal(1, t.n3[2])
      end

      def test_to_s
        t = gen(10, 16, 0)
        
        assert_equal("10", t.n1.to_s)
        assert_equal("a",  t.n1.to_s(16))
        assert_equal("10", t.n2.to_s(16))
      end

      def test_operation
        t = gen(2, 3, 3)

        assert_equal(BuiltInTemplate::UInt, t.n1.class)

        assert_equal(3, t.n1 + 1)
        assert_equal(4, t.n1 * 2)
        assert_equal(1, t.n1 - 1)
        assert_equal(1, t.n1 / 2)
        assert_equal(false, t.n1 == 1)
        assert_equal(true,  t.n1 == 2)
        assert_equal(true,  t.n1 != 1)
        assert_equal(false, t.n1 != 2)
        assert_equal(false, t.n1 < 1)
        assert_equal(true,  t.n1 > 1)

        assert_equal(3, 1 + t.n1)
        assert_equal(4, 2 * t.n1)
        assert_equal(1, 3 - t.n1)
        assert_equal(1, 2 / t.n1)
        assert_equal(false, 1 == t.n1)
        assert_equal(true,  2 == t.n1)
        assert_equal(true,  1 != t.n1)
        assert_equal(false, 2 != t.n1)
        assert_equal(true, 1 < t.n1)
        assert_equal(false,  1 > t.n1)

        assert_equal(5,  t.n1 + t.n2)
        assert_equal(6,  t.n1 * t.n2)
        assert_equal(-1, t.n1 - t.n2)
        assert_equal(0,  t.n1 / t.n2)
        
        assert_equal(false, t.n1 == t.n2)
        assert_equal(true,  t.n2 == t.n3)
      end

      # helper for generating binary
      def gen(*chars)
        return TestingTemplate.new(chars.pack("C*"))
      end
    end
  end
end
