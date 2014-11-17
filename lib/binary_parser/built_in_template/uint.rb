module BinaryParser
  module BuiltInTemplate
    class UInt < TemplateBase

      include Comparable

      def content_description
        "#{self.to_i.to_s} (0x#{self.to_i.to_s(16)})"
      end

      def to_s(base=10)
        self.to_i.to_s(base)
      end

      def [](bit_index)
        self.to_i[bit_index]
      end

      def coerce(other)
        if other.is_a?(Integer)
          return other, self.to_i
        else
          super
        end
      end

      def +(other)
        if other.is_a?(UInt)
          self.to_i + other.to_i
        elsif other.is_a?(Integer)
          self.to_i + other
        else
          x, y = other.coerce(self)
          x + y
        end
      end

      def *(other)
        if other.is_a?(UInt)
          self.to_i * other.to_i
        elsif other.is_a?(Integer)
          self.to_i * other
        else
          x, y = other.coerce(self)
          x * y
        end
      end

      def -(other)
        if other.is_a?(UInt)
          self.to_i - other.to_i
        elsif other.is_a?(Integer)
          self.to_i - other
        else
          x, y = other.coerce(self)
          x - y
        end
      end

      def /(other)
        if other.is_a?(UInt)
          self.to_i / other.to_i
        elsif other.is_a?(Integer)
          self.to_i / other
        else
          x, y = other.coerce(self)
          x / y
        end
      end

      def <=>(other)
        if other.is_a?(UInt)
          self.to_i <=> other.to_i
        elsif other.is_a?(Integer)
          self.to_i <=> other
        else
          nil
        end
      end
    end
  end
end
