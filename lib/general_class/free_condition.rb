module BinaryParser
  class FreeCondition
    def initialize(&condition_proc)
      @condition_proc = condition_proc
    end

    def eval(&name_eval_proc)
      @name_eval_proc = name_eval_proc
      return Proxy.new(self, []).instance_eval(&@condition_proc)
    end

    def symbol_call(var_name, *args, &block)
      @name_eval_proc.call(var_name)
    end
  end
end
