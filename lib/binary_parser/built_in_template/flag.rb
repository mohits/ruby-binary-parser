module BinaryParser
  module BuiltInTemplate
    class Flag < TemplateBase

      def on?
        return to_i[0] == 1
      end

      alias_method :flagged?, :on?

      def off?
        return !on?
      end

      alias_method :unflagged?, :off?

      def content_description
        on? ? "true" : "false"
      end
    end
  end
end
