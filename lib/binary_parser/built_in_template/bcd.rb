module BinaryParser
  module BuiltInTemplate
    def self.bcd_make(floating_point)
      klass = Class.new(TemplateBase) do
        Def do
          SPEND rest, :decimals, UInt4
        end

        def self.floating_point
          @floating_point
        end

        def floating_point
          self.class.floating_point
        end

        def to_i
          decimals.inject(0){|acc, n| acc * 10 + n.to_i}
        end

        def to_s
          return to_i.to_s if floating_point == 0
          to_i.to_s.insert(-(floating_point + 1), ".")
        end

        def to_f
          to_s.to_f
        end

        def content_description
          to_s
        end
      end
      
      klass.instance_variable_set(:@floating_point, floating_point)
      return klass
    end


    BCD = bcd_make(0)
    BCD_f1 = bcd_make(1)
    BCD_f2 = bcd_make(2)
    BCD_f3 = bcd_make(3)
    BCD_f4 = bcd_make(4)
    BCD_f5 = bcd_make(5)
    BCD_f6 = bcd_make(6)
    BCD_f7 = bcd_make(7)
    BCD_f8 = bcd_make(8)
    BCD_f9 = bcd_make(9)
    BCD_f10 = bcd_make(10)
  end
end
