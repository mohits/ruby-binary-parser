# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.dirname(File.expand_path(File.dirname(__FILE__))))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class ExpressionTest < Test::Unit::TestCase
      VAL = {:a =>  1, :b =>  2, :c =>  3, :d =>  4}
      LEN = {:a =>  5, :b =>  6, :c =>  7, :d =>  8}
      CON = {:a => -1, :b => -2, :c => -3, :d => -4}

      def test_expression
        exp = (1 + val(:a)) * len(:b) + 2 * con(:c) - (3 % val(:d))
        res = exp.eval do |token|
          if token.value_var?
            VAL[token.symbol]
          elsif token.length_var?
            LEN[token.symbol]
          elsif token.control_var?
            CON[token.symbol]
          end
        end
        
        assert_equal((1 + 1) * 6 + 2 * -3 - (3 % 4), res)
      end

      # helpers
      
      def val(symbol)
        Expression.value_var(symbol)
      end

      def len(symbol)
        Expression.length_var(symbol)
      end

      def con(symbol)
        Expression.control_var(symbol)
      end
    end
  end
end
