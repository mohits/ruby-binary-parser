module BinaryParser
  module BuiltInTemplate
    class UInt < TemplateBase
      def content_description
        to_i.to_s
      end
    end
  end
end
