module BinaryParser
  class Condition
    def initialize(*var_names, &condition_proc)
      @tokens = var_names.map{|symbol| Expression.value_var(symbol)}
      @condition_proc = condition_proc
    end

    def eval(&token_eval_proc)
      return @condition_proc.call(*@tokens.map{|token| token_eval_proc.call(token)})
    end
  end
end
