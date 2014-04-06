# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/general_class/expression.rb'

    class ExpressionTest < Test::Unit::TestCase
      VAL = {:hoge => 10, :fuga => 1000}

      def test_expression
        var_exp1 = Expression.new([:hoge])
        var_exp2 = Expression.new([:fuga])
        exp = (var_exp1 + 3) * 12 + var_exp2 / 10 - 4
        assert_equal((10 + 3) * 12 + 1000 / 10 - 4, exp.eval{|name| VAL[name]})
      end
    end
  end
end
