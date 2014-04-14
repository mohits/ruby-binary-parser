# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class ConditionTest < Test::Unit::TestCase

      VAL = {:hoge => 10, :fuga => 1000}  

      def test_condition
        cond1 = Condition.new(:hoge, :fuga){|v1, v2| v1 * 100 == v2}
        cond2 = Condition.new(:hoge, :fuga){|v1, v2| v1 * 10  == v2}
        assert_equal(true,  cond1.eval{|name| VAL[name]})
        assert_equal(false, cond2.eval{|name| VAL[name]})
      end
    end
  end
end
