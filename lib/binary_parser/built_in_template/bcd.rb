module BinaryParser
  module BuiltInTemplate

    BCD = Object.new

    def BCD.[](floating_point)
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
  end
end
