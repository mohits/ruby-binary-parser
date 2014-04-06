# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/general_class/bit_position.rb'

    class BitPositionTest < Test::Unit::TestCase

      VAL = {:hoge => 10, :fuga => 1000}

      def test_bit_position
        bp = BitPosition.new
        pos = bp.add_imm(4).add_name(:hoge).add_imm(3).add_name(:fuga).eval{|name| VAL[name]}
        assert_equal(1017, pos)
      end
    end
  end
end
