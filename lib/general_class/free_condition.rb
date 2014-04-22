module BinaryParser
  class FreeCondition
    def initialize(&condition_proc)
      @condition_proc = condition_proc
    end

    def eval(&name_eval_proc)
      @name_eval_proc = name_eval_proc
      return Proxy.new(self, []).instance_eval(&@condition_proc)
    end

    def symbol_call(symbol, *args, &block)
      if symbol == :nextbits && args.length == 1
        @name_eval_proc.call(Expression.nextbits_var(args[0]))
      else
        @name_eval_proc.call(Expression.value_var(symbol))
      end
    end
  end
end
