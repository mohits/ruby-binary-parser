# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'
    
    class BCDTemplateTest < Test::Unit::TestCase
      
      class TestingTemplate < TemplateBase
        def_structure do
          data :n1, BCD, 16
          data :n2, BCD_f1, 16
          data :n3, BCD_f5, 32
        end
      end

      def test_to_i
        t = gen(0x20, 0x14, 0x11, 0x26, 0x01, 0x23, 0x45, 0x67)
        
        assert_equal(2014,    t.n1.to_i)
        assert_equal(1126,    t.n2.to_i)
        assert_equal(1234567, t.n3.to_i)
      end

      def test_to_s
        t = gen(0x20, 0x14, 0x11, 0x26, 0x01, 0x23, 0x45, 0x67)

        assert_equal("2014",     t.n1.to_s)
        assert_equal("112.6",    t.n2.to_s)
        assert_equal("12.34567", t.n3.to_s)
      end

      # helper for generating binary
      def gen(*chars)
        return TestingTemplate.new(chars.pack("C*"))
      end
    end
  end
end
