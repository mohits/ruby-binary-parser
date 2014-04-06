module BinaryParser
  class Condition
    def initialize(*var_names, &condition_proc)
      @var_names, @condition_proc = var_names, condition_proc
    end

    def eval(&name_eval_proc)
      return @condition_proc.call(*@var_names.map{|name| name_eval_proc.call(name)})
    end
  end
end
