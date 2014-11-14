module BinaryParser
  module BuiltInTemplate
    class Binary < TemplateBase
      def content_description
        chars = to_chars
        bytes = chars[0, 5].map{|i| sprintf("0x%02x", i)}.join(", ")
        return "[" + bytes + (chars.length > 5 ? ", ..." : "") + "]"
      end

      def to_str
        self.to_s
      end

      def ==(other)
        if other.is_a?(Binary)
          self.to_s == other.to_s
        elsif other.is_a?(String)
          self.to_s == other
        else
          super
        end
      end
    end
  end
end

