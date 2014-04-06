module BinaryParser
  class Expression
    attr_reader :rpn

    def initialize(rpn)
      @rpn = rpn
    end

    def +(other)
      return Expression.new(@rpn + to_rpn(other) + [:__add])
    end

    def -(other)
      return Expression.new(@rpn + to_rpn(other) + [:__sub])
    end

    def *(other)
      return Expression.new(@rpn + to_rpn(other) + [:__mul])
    end

    def /(other)
      return Expression.new(@rpn + to_rpn(other) + [:__div])
    end

    def to_rpn(other)
      case other
      when Integer
        return [other]
      when Expression
        return other.rpn
      else
        raise BadManipulationError, "Unknown type of other (#{other.class})."
      end
    end

    def variables
      control_symbols = [:__add, :__sub, :__mul, :__div]
      return @rpn.select{|token| token.is_a?(Symbol) && !control_symbols.include?(token)}
    end

    def eval(&name_eval_block)
      stack, rpn = [], @rpn.dup
      until rpn.empty?
        stack << rpn.shift
        case stack.last
        when :__add
          arg = [stack.pop, stack.pop, stack.pop]
          stack << arg[2] + arg[1]
        when :__sub
          arg = [stack.pop, stack.pop, stack.pop]
          stack << arg[2] - arg[1]
        when :__mul
          arg = [stack.pop, stack.pop, stack.pop]
          stack << arg[2] * arg[1]
        when :__div
          arg = [stack.pop, stack.pop, stack.pop]
          stack << arg[2] / arg[1]
        when Symbol
          stack << name_eval_block.call(stack.pop)
        end
      end
      raise ProgramAssertionError, "Cannot calc RPN." unless stack.length == 1
      return stack.last
    end
  end
end
