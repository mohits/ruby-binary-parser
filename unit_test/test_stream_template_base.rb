# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'
    
    class TemplateStreamBaseTest < Test::Unit::TestCase
      require 'stringio'

      class TestingStreamTemplate < StreamTemplateBase
        MyInt = Class.new(TemplateBase)
        MyBin = Class.new(TemplateBase)

        def_stream(3) do
          data :id,   MyInt, 8
          data :flag, MyInt, 8
          data :char, MyBin, 8
        end
      end

      def test_get_next_SIMPLE_USE
        st = gen_stream(1, 0, 0x41,
                        2, 1, 0x42)

        d1 = st.get_next
        assert_equal(1,   d1.id.to_i)
        assert_equal(0,   d1.flag.to_i)
        assert_equal("A", d1.char.to_s)

        d2 = st.get_next
        assert_equal(2,   d2.id.to_i)
        assert_equal(1,   d2.flag.to_i)
        assert_equal("B", d2.char.to_s)

        assert_not(st.rest?)
        assert_equal(nil, st.get_next)
      end

      def test_get_next_BINARY_SHORTAGE_ERROR
        st = gen_stream(1, 0, 0x41, 0)

        st.get_next
        assert_raise(ParsingError) do
          st.get_next
        end
      end

      def test_filter_AND_get_next
        st = gen_stream(1, 0, 0,
                        2, 1, 0,
                        3, 0, 0,
                        4, 1, 0)

        d1 = st.filter{|a| a.flag.to_i == 1}.get_next
        assert_equal(2, d1.id.to_i)
        
        d2 = st.get_next
        assert_equal(3, d2.id.to_i)

        d3 = st.filter{|a| a.flag.to_i == 0}.get_next
        assert_equal(nil, d3)

        assert_not(st.rest?)

        d4 = st.get_next
        assert_equal(nil, d4)
      end

      def test_read
        st = gen_stream(1, 2, 3,
                        4, 5, 6,
                        7, 8, 9)

        ss = st.read(2)
        assert_equal(2, ss.length)
        assert_equal(1, ss[0].id.to_i)
        assert_equal(4, ss[1].id.to_i)
        
        ss = st.read(2)
        assert_equal(1, ss.length)
        assert_equal(7, ss[0].id.to_i)

        ss = st.read(2)
        assert_equal(0, ss.length)
      end
      
      def test_seek_top_POPULAR_CASE
        st = gen_stream(1, 0, 0,
                        2, 0, 0,
                        3, 1, 0,
                        4, 0, 0)

        abandoned = st.seek_top{|a| a.flag.to_i == 1}
        assert_equal(2, abandoned.size)
        assert_equal(1, abandoned[0].id.to_i)
        assert_equal(2, abandoned[1].id.to_i)

        assert_equal(3, st.get_next.id.to_i)
      end

      def test_seek_top_SPECIAL_CASE1
        st = gen_stream(1, 1, 0,
                        2, 0, 0)
        
        abandoned = st.seek_top{|a| a.flag.to_i == 1}
        assert_equal(0, abandoned.size)
        assert_equal(1, st.get_next.id.to_i)
      end

      def test_seek_top_SPECIAL_CASE2
        st = gen_stream(1, 0, 0,
                        2, 0, 0)
        
        abandoned = st.seek_top{|a| a.flag.to_i == 1}
        assert_equal(2, abandoned.size)
        assert_not(st.rest?)
        assert_equal(nil, st.get_next)
      end

      def test_seek_top_SPECIAL_CASE3
        st = gen_stream()
        
        abandoned = st.seek_top{|a| a.flag.to_i == 1}
        assert_equal(0, abandoned.size)
        assert_not(st.rest?)
        assert_equal(nil, st.get_next)
      end

      def test_get_sequence_POPULAR_CASE
        st = gen_stream(1, 0, 0,
                        2, 1, 0,
                        3, 0, 0,
                        4, 0, 0,
                        5, 1, 0)

        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(3, seq.size)
        assert_equal(2, seq[0].id.to_i)
        assert_equal(3, seq[1].id.to_i)
        assert_equal(4, seq[2].id.to_i)

        assert(st.rest?)
        assert_equal(5, st.get_next.id.to_i)
      end
      
      def test_get_sequence_SPECIAL_CASE1
        st = gen_stream(1, 1, 0,
                        2, 0, 0,
                        3, 1, 0)
        
        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(2, seq.size)

        assert_equal(3, st.get_next.id.to_i)
      end

      def test_get_sequence_SPECIAL_CASE2
        st = gen_stream(1, 1, 0,
                        2, 1, 0,
                        3, 0, 0)
        
        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(1, seq.size)

        assert_equal(2, st.get_next.id.to_i)
      end

      def test_get_sequence_SPECIAL_CASE3_A
        st = gen_stream(1, 1, 0,
                        2, 0, 0)
        
        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(0, seq.size)

        assert_not(st.rest?)
      end

      def test_get_sequence_SPECIAL_CASE3_B
        st = gen_stream(1, 1, 0,
                        2, 0, 0)
        
        seq = st.get_sequence(true){|a| a.flag.to_i == 1}
        assert_equal(2, seq.size)

        assert_not(st.rest?)
      end

      def test_get_sequence_SPECIAL_CASE4
        st = gen_stream(1, 0, 0,
                        2, 0, 0)
        
        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(0, seq.size)

        assert_not(st.rest?)
      end

      def test_get_sequence_SPECIAL_CASE5
        st = gen_stream()
        
        seq = st.get_sequence{|a| a.flag.to_i == 1}
        assert_equal(0, seq.size)

        assert_not(st.rest?)
      end

      def test_accumulate_POPULAR_CASE
        st = gen_stream(1, 0, 0,
                        2, 0, 0,
                        3, 0, 0,
                        4, 0, 0,
                        5, 0, 0)
        
        reduced_list = st.accumulate(0, 6){|acc, a| acc + a.id.to_i}
        assert_equal(3, reduced_list.size)

        assert_equal(4, st.get_next.id.to_i)
      end

      def test_accumulate_SPECIAL_CASE
        st = gen_stream(1, 0, 0,
                        2, 0, 0,
                        3, 0, 0)

        reduced_list = st.accumulate(0, 7){|acc, a| acc + a.id.to_i}
        assert_equal(nil, reduced_list)

        assert_not(st.rest?)
      end

      # helpers
      def gen_bin(*chars)
        return chars.pack("C*")
      end

      def gen_stream(*args)
        binary_stream = StringIO.new(gen_bin(*args))
        return TestingStreamTemplate.new(binary_stream)
      end

      def assert_not(object)
        assert(!object)
      end
    end
  end
end
