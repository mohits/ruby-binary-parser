module BinaryParser
  module Memorize
    module Extension

      attr_accessor :memorize_methods
      
      def method_added(method_name)
        @memorized ||= Hash.new
        if @memorize_methods.include?(method_name) && !@memorized[method_name]
          @memorized[method_name] = true
          memorize(method_name) 
        end
      end

      def memorize(method_name)
        pure_method_name = "pure_#{method_name}".to_sym
        alias_method pure_method_name, method_name
        define_method(method_name) do |arg|
          @memo ||= Hash.new
          @memo[method_name] ||= Hash.new
          @memo[method_name][arg] ||= send(pure_method_name, arg)
        end
      end
    end

    def self.one_arg_method(*method_names)
      @method_names = method_names
      return self
    end

    def self.included(klass)
      klass.extend Extension
      klass.memorize_methods = @method_names
    end
  end
end
