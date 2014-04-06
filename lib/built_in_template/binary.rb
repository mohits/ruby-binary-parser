module BinaryParser
  module BuiltInTemplate
    class Binary < TemplateBase
      def content_description
        chars = to_chars
        bytes = chars[0, 5].map{|i| sprintf("0x%02x", i)}.join(", ")
        return "[" + bytes + (chars.length > 5 ? ", ..." : "") + "]"
      end
    end
  end
end

