# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class FreeConditionTest < Test::Unit::TestCase

      def test_free_condition
        cond1 = FreeCondition.new{ v1 * 100 == v2 }
        assert_equal(true,  cond1.eval{|name| {:v1 => 1, :v2 => 100}[name]})
        assert_equal(false, cond1.eval{|name| {:v1 => 2, :v2 => 100}[name]})
      end
    end
  end
end
