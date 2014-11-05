# -*- coding: utf-8 -*-
$LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

module BinaryParser
  module UnitTest
    require 'test/unit'

    # load testing target
    require $LIBRARY_ROOT_PATH + '/lib/binary_parser.rb'

    class ScopeTest < Test::Unit::TestCase
      
      # TEST CASE STRUCTURE 1
      # * roughly test various
      class ST1 < TemplateBase
        Def do
          data :cond_num, UInt, 8
          IF cond(:cond_num){|v| v.to_i == 1} do
            data :length, UInt, 8
            data :data,   Binary, var(:length) * 8
          end
          
          data :binary_len, UInt, 8
          SPEND var(:binary_len) * 8, :list do
            data :length, UInt, 8
            data :data,   Binary, var(:length) * 8
          end

          data :foot, UInt, 32
        end
      end

      def test_ST1_CASE1
        bin = gen_bin(*[0x01, [0x04, [0x48, 0x4f, 0x47, 0x45]],
                        0x06, [0x1, [0x70], 0x3, [0x69, 0x79, 0x6f]],
                        0xff, 0xff, 0xff, 0xff].flatten)

        sc = ST1.new(bin)

        assert_equal(1,      sc.cond_num.to_i)
        assert_equal(4,      sc.length.to_i)
        assert_equal("HOGE", sc.data.to_s)

        assert_equal(6,      sc.binary_len.to_i)
        assert_equal(2,      sc.list.size)
        assert_equal("p",    sc.list[0].data.to_s)
        assert_equal("iyo",  sc.list[1].data.to_s)   
        
        assert_equal(0xffffffff, sc.foot.to_i)
      end

      # TEST CASE STRUCTURE 2
      # * about IF
      class ST2 < TemplateBase
        Def do
          data :number1, UInt, 8
          IF cond(:number1){|v| v.to_i == 1} do
            data :number2, UInt, 8
            IF cond(:number2){|v| v.to_i == 2} do
              data :number3, UInt, var(:number2) * 4
            end
          end
          data :number4, UInt, 8
        end
      end

      def test_ST2_CASE1
        bin = gen_bin(1, 2, 3, 4)
        i = ST2.new(bin)

        assert_equal(1, i.number1.to_i)
        assert_equal(2, i.number2.to_i)
        assert_equal(3, i.number3.to_i)
        assert_equal(4, i.number4.to_i)
        assert(i.hold_just_binary?)
      end

      def test_ST2_CASE2
        bin = gen_bin(1, 0, 4)
        i = ST2.new(bin)

        assert_equal(1,   i.number1.to_i)
        assert_equal(0,   i.number2.to_i)
        assert_equal(nil, i.number3)
        assert_equal(4,   i.number4.to_i)
        assert(i.hold_just_binary?)
      end

      def test_ST2_CASE3
        bin = gen_bin(0, 4)
        i = ST2.new(bin)
        
        assert_equal(0,   i.number1.to_i)
        assert_equal(nil, i.number2)
        assert_equal(nil, i.number3)
        assert_equal(4,   i.number4.to_i)
        assert(i.hold_just_binary?)
      end

      # TEST CASE STRUCTURE 3
      # * SPEND and TIMES
      class ST3 < TemplateBase
        Def do
          data :size, UInt, 8
          SPEND var(:size), :l1 do
            data :dat, UInt, 8
          end
          data :times, UInt, 8
          TIMES var(:times), :l2 do
            data :dat, UInt, 8
          end
          data :dat, UInt, 8
        end
      end

      def test_ST3_CASE1
        bin = gen_bin(0, 0, 0xff)
        i = ST3.new(bin)

        assert_equal(0,    i.size.to_i)
        assert_equal(0,    i.l1.size)
        assert_equal(0,    i.times.to_i)
        assert_equal(0,    i.l2.size)
        assert_equal(0xff, i.dat.to_i)
        assert(i.hold_just_binary?)
      end

      # TEST CASE STRUCTURE 4
      # * Dynamic length test
      class ST4 < TemplateBase
        Def do
          data :v1, UInt, 8
          data :v2, UInt, var(:v1)
          data :v3, UInt, var(:v2)
          data :v4, UInt, rest
          data :v5, UInt, rest
        end
      end

      def test_ST4_CASE1
        bin = gen_bin(8, 0, 0xff, 0xff)
        i = ST4.new(bin)

        assert_equal(8,      i.v1.to_i)
        assert_equal(0,      i.v2.to_i)
        assert_equal(nil,    i.v3)
        assert_equal(0xffff, i.v4.to_i)
        assert_equal(nil,    i.v5)
        assert(i.hold_just_binary?)
      end

      def test_ST4_CASE2
        bin = gen_bin(8, 8, 0xff)
        i = ST4.new(bin)

        assert_equal(8,    i.v1.to_i)
        assert_equal(8,    i.v2.to_i)
        assert_equal(0xff, i.v3.to_i)
        assert_equal(nil,  i.v4)
        assert_equal(nil,  i.v5)
        assert(i.hold_just_binary?)
      end

      # TEST CASE STRUCTURE 5
      # * structure size test
      class ST5 < TemplateBase
        Def do
          data :v1, UInt, 8
          data :v2, UInt, var(:v1)
          data :v3, UInt, var(:v2)
        end
      end

      def test_ST5_CASE1
        i1 = ST5.new(gen_bin(8, 8))
        assert(!i1.hold_enough_binary?)
          
        i2 = ST5.new(gen_bin(8))
        assert_raise(ParsingError) do
          assert(!i2.hold_enough_binary?)
        end
      end

      # TEST CASE STRUCTURE 6
      # * len test
      class ST6 < TemplateBase
        Def do
          data :id,           UInt,   8
          data :whole_length, UInt,   8
          data :rest_binary,  Binary, var(:whole_length) - len(:id) - len(:whole_length)
        end
      end

      def test_ST6_CASE1
        i = ST6.new(gen_bin(0, 32, 0x41, 0x42, 0x43))
        assert_equal(16, i.rest_binary.binary_bit_length)
        assert_equal("AB", i.rest_binary.to_s)
      end

      # TEST CASE STRUCTURE 7
      # * position
      class ST7 < TemplateBase
        Def do
          data :id,           UInt,   8
          data :whole_length, UInt,   8
          data :rest_binary,  Binary, var(:whole_length) - position
        end
      end

      def test_ST7_CASE1
        i = ST7.new(gen_bin(0, 32, 0x41, 0x42, 0x43))
        assert_equal(16, i.rest_binary.binary_bit_length)
        assert_equal("AB", i.rest_binary.to_s)
      end

      # TEST CASE STRUCTURE 8
      # * nextbits
      class ST8 < TemplateBase
        Def do
          data :n1, UInt, nextbits(8) * 8
          data :n2, UInt, 8
        end
      end

      def test_ST8_CASE1
        i = ST8.new(gen_bin(3, 0, 0, 1))
        assert_equal(24, i.n1.binary_bit_length)
        assert_equal(0x030000, i.n1)
        assert_equal(1, i.n2)
      end

      # TEST CASE STRUCTURE 9
      # * WHILE
      class ST9 < TemplateBase
        Def do
          WHILE E{ nextbits(4) == 0xA }, :ls do
            data :id, UInt, 8
          end
          data :suffix, UInt, 8
        end
      end

      def test_ST9_CASE1
        i = ST9.new(gen_bin(0xA1, 0xA2, 0xA3, 0xB4))

        assert_equal(3, i.ls.length)
        assert_equal(0xA1, i.ls[0].id)
        assert_equal(0xA2, i.ls[1].id)
        assert_equal(0xA3, i.ls[2].id)
        assert_equal(0xB4, i.suffix)
        assert_equal(4 * 8, i.structure_bit_length)
      end

      def test_ST9_CASE2
        i = ST9.new(gen_bin(0xB0))

        assert_equal(0, i.ls.length)
        assert_equal(0xB0, i.suffix)
        assert_equal(1 * 8, i.structure_bit_length)
      end

      # TEST CASE STRUCTURE 10
      # * new way of SPEND and TIMES
      class ST10 < TemplateBase

        class ST10SPEND < TemplateBase
          Def do
            data :dat, UInt, 8
          end
        end

        class ST10TIMES < TemplateBase
          Def do
            data :dat, UInt, 8
          end
        end

        Def do
          data :spend_size, UInt, 8
          SPEND var(:spend_size) * 8, :spend_datas, ST10SPEND
          data :times, UInt, 8
          TIMES var(:times), :times_datas, ST10TIMES
        end
      end

      def test_ST10_CASE1
        bin = gen_bin(2, 0xaa, 0xbb, 2, 0xcc, 0xdd)
        i = ST10.new(bin)

        assert_equal(2,    i.spend_size.to_i)
        assert_equal(0xaa, i.spend_datas[0].dat.to_i)
        assert_equal(0xbb, i.spend_datas[1].dat.to_i)
        assert_equal(2,    i.times.to_i)
        assert_equal(0xcc, i.times_datas[0].dat.to_i)
        assert_equal(0xdd, i.times_datas[1].dat.to_i)
        assert(i.hold_just_binary?)
      end


      # helpers
      def gen_bin(*chars)
        return AbstractBinary.new(chars.pack("C*"))
      end
    end
  end
end

