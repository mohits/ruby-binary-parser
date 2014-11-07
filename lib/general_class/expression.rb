module BinaryParser
  class Expression

    def self.value_var(symbol)
      Token::Variable::Value.new(symbol)
    end

    def self.length_var(symbol)
      Token::Variable::Length.new(symbol)
    end

    def self.control_var(symbol)
      Token::Variable::Control.new(symbol)
    end

    def self.nextbits_var(length)
      Token::Variable::Nextbits.new(length)
    end

    def self.immediate(value)
      Token::Immediate.new(value)
    end

    def value_var?
      self.is_a?(Token::Variable::Value)
    end

    def length_var?
      self.is_a?(Token::Variable::Length)
    end

    def control_var?
      self.is_a?(Token::Variable::Control)
    end

    def nextbits_var?
      self.is_a?(Token::Variable::Nextbits)
    end

    def immediate?
      self.is_a?(Token::Immediate)
    end

    def coerce(other)
      if other.is_a?(Integer)
        return Token::Immediate.new(other), self
      else
        super
      end
    end

    def +(other)
      binary_op(other, Token::Operator::Add.instance)
    end

    def -(other)
      binary_op(other, Token::Operator::Sub.instance)
    end

    def *(other)
      binary_op(other, Token::Operator::Mul.instance)
    end

    def /(other)
      binary_op(other, Token::Operator::Div.instance)
    end

    def %(other)
      binary_op(other, Token::Operator::Mod.instance)
    end

    def binary_op(other, op)
      BinaryOperator.new(self, other, op)
    end

    def to_exp(exp)
      if exp.is_a?(Expression)
        exp
      elsif exp.is_a?(Integer)
        Token::Immediate.new(exp)
      else
        raise BadManipulationError, "Can't convert #{exp} into Expression."
      end
    end

    def eval(&token_eval_proc)
      to_rpn.eval(&token_eval_proc)
    end

    def variable_tokens
      to_rpn.tokens.select{|token| token.is_a?(Token::Variable)}
    end

    def initialize(*args)
      raise BadManipulationError, "Expression is abstract class."
    end

    class BinaryOperator < self
      def initialize(chl, chr, op)
        check_op(op)
        @chl, @chr, @op = to_exp(chl), to_exp(chr), op
      end

      def check_op(op)
        unless op.is_a?(Token::Operator)
          raise BadManipulationError, "Argument should be Token::Operator."
        end
      end

      def to_rpn
        @rpn ||= @chl.to_rpn + @chr.to_rpn + @op.to_rpn
      end
    end

    class Token < self

      def initialize
        #override but do nothing
      end

      def to_rpn
        @rpn ||= RPN.new(self)
      end

      class Variable < self

        attr_reader :symbol

        def initialize(symbol)
          raise BadManipulationError, "Argument should be Symbol." unless symbol.is_a?(Symbol)
          @symbol = symbol
        end

        class Length < self

        end

        class Value < self

        end

        class Control < self

        end

        class Nextbits < self

          attr_reader :length

          def initialize(length)
            unless length.is_a?(Integer) && length > 0
              raise BadManipulationError, "Argument should be positive Integer."
            end
            @length = length
          end
        end
      end

      class Immediate < self

        attr_reader :value

        def initialize(value)
          raise BadManipulationError, "Argument should be Integer." unless value.is_a?(Integer)
          @value = value
        end
      end

      class Operator < self

        require 'singleton'
        include Singleton

        class Add < self
          def operate(op1, op2)
            op1 + op2
          end
        end

        class Sub < self
          def operate(op1, op2)
            op1 - op2
          end
        end

        class Mul < self
          def operate(op1, op2)
            op1 * op2
          end
        end

        class Div < self
          def operate(op1, op2)
            op1 / op2
          end
        end

        class Mod < self
          def operate(op1, op2)
            op1 % op2
          end
        end
      end
    end

    class RPN
      attr_reader :tokens

      def initialize(*tokens)
        check_tokens(tokens)
        @tokens = tokens
      end

      def check_tokens(tokens)
        tokens.all?{|token| token.is_a?(Expression::Token)}
      end

      def +(other)
        RPN.new(*(self.tokens + other.tokens))
      end

      def eval(&token_eval_proc)
        stack = @tokens.inject([]) do |stack, token|
          if token.is_a?(Expression::Token::Operator)
            raise BadManipulationError, "Cannot calculate this RPN." if stack.length < 2
            stack + [token.operate(*[stack.pop, stack.pop].reverse)]
          elsif token.is_a?(Expression::Token::Immediate)
            stack + [token.value]
          elsif token.is_a?(Expression::Token::Variable)
            eval_value = token_eval_proc.call(token)
            unless eval_value.is_a?(Integer) || eval_value.is_a?(::BinaryParser::BuiltInTemplate::UInt)
              raise BadManipulationError, "Evaluation is faild. #{eval_value} is not Integer (or UInt) (#{eval_value.class})."
            end
            stack + [eval_value]
          end
        end
        raise BadManipulationError, "Cannot calculate this RPN." if stack.length != 1
        return stack.last
      end
    end
  end
end
