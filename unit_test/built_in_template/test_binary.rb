# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'
    
    class BinaryTemplateTest < Test::Unit::TestCase
      
      class TestingTemplate < TemplateBase
        def_structure do
          data :b1, Binary, 16
          data :b2, Binary, 16
          data :b3, Binary, 16
        end
      end

      def test_data_method_block_call
        t = gen(0x41, 0x42, 0x41, 0x42, 0, 0)

        assert_equal(true, t.b1 == "AB")
        assert_equal(false, t.b1 == "BA")

        assert_equal(true, "AB" == t.b1)
        assert_equal(false,"BA" == t.b1)

        assert_equal(true,  t.b1 == t.b2)
        assert_equal(false, t.b1 == t.b3)
      end

      # helper for generating binary
      def gen(*chars)
        return TestingTemplate.new(chars.pack("C*"))
      end
    end
  end
end
