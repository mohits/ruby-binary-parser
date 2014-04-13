# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class StructureDefinitionTest < Test::Unit::TestCase

      C1 = Class.new(TemplateBase)
      C2 = Class.new(TemplateBase)
      C3 = Class.new(TemplateBase)
        
      def test_data
        st = StructureDefinition.new do
          data :a, C1, 3
          data :b, C2, var(:a) * 8
          data :c, C3, 4
        end

        assert_equal(C1, st[:a].klass)
        assert_equal(0,  st[:a].bit_position.eval{})
        assert_equal(3,  st[:a].bit_length.eval{})
        assert_equal([], st[:a].conditions)

        assert_equal(C2, st[:b].klass)
        assert_equal(3,  st[:b].bit_position.eval{})
        assert_equal(24, st[:b].bit_length.eval{|name| {:a => 3}[name]})
        assert_equal([], st[:b].conditions)

        assert_equal(C3, st[:c].klass)
        assert_equal(27, st[:c].bit_position.eval{|name| {:b => 24}[name]})
        assert_equal(4,  st[:c].bit_length.eval{})
        assert_equal([], st[:c].conditions)
      end

      def test_SPEND
        st = StructureDefinition.new do
          SPEND 48, :lp do
            data :dat1, C1, 8
            data :dat2, C2, 16
          end
          data :dat3, C3, 8
        end
        
        assert_equal(8,  st[:lp].structure[:dat1].bit_length.eval{})
        assert_equal(16, st[:lp].structure[:dat2].bit_length.eval{})
        assert_equal(48, st[:dat3].bit_position.eval{})
      end

      def test_TIMES
        st = StructureDefinition.new do
          data :outer, C1, 8
          TIMES 4, :list do
            data :inner, C1, var(:outer)
          end
          data :foot, C1, 8
        end
        
        assert_equal(8,  st[:list].bit_position.eval{})
        assert_equal(12, st[:list].bit_length.eval{|name| {:outer => 3}[name]})
        assert_equal(20, st[:foot].bit_position.eval{|name| {:list => 12}[name]})
      end

      def test_IF
        st = StructureDefinition.new do
          data :dat1, C1, 3
          IF cond(:dat1){|v| v == 1} do
            data :dat2, C2, var(:dat1) * 8
            IF cond(:dat2){|v| v == 1} do
              data :dat3, C3, var(:dat2) * 8
            end
          end
          data :dat4, C1, 1
        end
      
        assert_equal(0, st[:dat1].conditions.size)
        assert_equal(1, st[:dat2].conditions.size)
        assert_equal(2, st[:dat3].conditions.size)
        assert_equal(0, st[:dat4].conditions.size)
      end

      def test_match
        st = StructureDefinition.new do
          data :hoge, C1, 1
          data :fuga, C1, 1
        end

        eval_proc = Proc.new do |var_name|
          {:hoge => 1, :fuga => 1}[var_name]
        end

        cond1 = st.match(:hoge, 1)
        assert_equal(true, cond1.eval(&eval_proc))

        cond2 = st.match(:hoge, "ABC")
        assert_equal(false, cond2.eval(&eval_proc))

        cond3 = st.match(:hoge, :fuga)
        assert_equal(true, cond3.eval(&eval_proc))

        assert_raise(DefinitionError) do
          st.match(:hoge, Object.new)
        end
      end

      def test_VARIABLE_REFERENCE_ERROR
        assert_raise(DefinitionError) do
          st = StructureDefinition.new do
            data :d1, C1, var(:d2) * 8
            data :d2, C2, 8
          end
        end
      end

      def test_TIMES_WITH_NONFIXED_LENGTH
         assert_nothing_raised do
          st = StructureDefinition.new do
            data :length, C1,   8
            TIMES 1, :list do
              data :dat, C2, var(:length) * 8
            end
          end
        end
         assert_raise(DefinitionError) do
          st = StructureDefinition.new do
            TIMES 1, :list do
              data :length, C1,   8
              data :dat,    C2, var(:length) * 8
            end
          end
        end
      end
    end
  end
end
