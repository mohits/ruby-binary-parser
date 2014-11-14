module BinaryParser
  class StructureDefinition
    
    DataDefinition  = Struct.new(:bit_position, :bit_length, :conditions, :klass)
    LoopDefinition  = Struct.new(:bit_position, :bit_length, :conditions, :klass)
    WhileDefinition = Struct.new(:bit_position, :bit_length, :conditions, :klass, :loop_condition)

    KEYWORDS = 
      [
       :data, :SPEND, :TIMES, :WHILE, :IF, :E, :cond, :match, :var, :len, :nextbits, :position,
       :rest, :[]
      ]

    attr_reader :parent_structure, :bit_at, :names
    
    def initialize(forbidden_method_names=[], parent_structure=nil, &init_proc)
      @forbidden_method_names = forbidden_method_names
      @parent_structure = parent_structure
      @bit_at = BitPosition.new     
      @data_def = {}
      @conditions, @names = [], []
      Proxy.new(self, KEYWORDS).instance_eval(&init_proc) if init_proc
    end

    def data(name, klass, bit_length)
      __check_new_def_name(name)
      unless klass.ancestors.include?(TemplateBase)
        raise DefinitionError, "Class #{klass} should be TemplateBase."
      end
      bit_at, bit_length = __process_bit_length(bit_length, name)
      define(name, DataDefinition.new(bit_at, bit_length, @conditions.dup, klass))
    end

    def SPEND(bit_length, name, klass=nil, &block)
      __check_new_def_name(name)
      bit_at, bit_length = __process_bit_length(bit_length, name)
      klass ||= NamelessTemplateMaker.new(self, block)
      define(name, LoopDefinition.new(bit_at, bit_length, @conditions.dup, klass))
    end

    def TIMES(times, name, klass=nil, &block)
      __check_new_def_name(name)
      klass ||= NamelessTemplateMaker.new(self, block)
      structure = klass.structure
      if structure.bit_at.names.empty?
        bit_at, bit_length = __process_bit_length(times * structure.bit_at.imm, name)
        define(name, LoopDefinition.new(bit_at, bit_length, @conditions.dup, klass))
      else
        bit_length = Expression.immediate(0)
        structure.bit_at.names.each do |depending_token|
          depending_length_exp = structure[depending_token.symbol].bit_length
          depending_length_exp.variable_tokens.each do |token|
            if structure[token.symbol]
              raise DefinitionError, "In '#{name}', same level variable #{token.symbol} is referenced." + 
                "*** TIMES's inner structure's bit-length must be always same." +
                "In other words, that bit-length must not rely on same level variables. ***"
            end
          end
          bit_length += depending_length_exp
        end
        bit_at, bit_length = __process_bit_length(bit_length * times, name)
        define(name, LoopDefinition.new(bit_at, bit_length, @conditions.dup, klass))
      end
    end

    def define(name, data)
      @data_def[name] = data
      @names << name
    end

    def WHILE(condition, name, &block)
      __check_new_def_name(name)
      klass = NamelessTemplateMaker.new(self, block)
      bit_at, bit_length = __process_bit_length(Expression.control_var(:non_fixed), name)
      define(name, WhileDefinition.new(bit_at, bit_length, @conditions.dup, klass, condition))
    end
      
    def IF(condition, &block)
      @conditions.push(condition)
      block.call
      @conditions.pop
    end

    def cond(*var_names, &condition_proc)
      var_names.each do |var_name|
        unless __name_resolvable?(var_name)
          raise DefinitionError, "As condition variable, unsolvable variable #{var_name} is used."
        end
      end
      return Condition.new(*var_names, &condition_proc)
    end

    def E(&condition_proc)
      return FreeCondition.new(&condition_proc)
    end

    def match(var_name, value)
      case value
      when Integer
        return cond(var_name){|v| v.to_i == value}
      when String
        return cond(var_name){|v| v.to_s == value}
      when Symbol
        return cond(var_name, value){|v1, v2| v1.to_i == v2.to_i}
      else
        raise DefinitionError, "Unknown type of matching value(#{value}) '#{value.class}'."
      end
    end

    def var(var_name)
      unless __name_resolvable?(var_name)
        raise DefinitionError, "Unsolvable variable #{var_name} is used."
      end
      return Expression.value_var(var_name)
    end

    def len(var_name)
      unless __name_resolvable?(var_name)
        raise DefinitionError, "Unsolvable variable #{var_name} is used."
      end
      return Expression.length_var(var_name)
    end

    def nextbits(length)
      return Expression.nextbits_var(length)
    end

    def position
      Expression.control_var(:position)
    end

    def rest
      Expression.control_var(:rest)
    end

    def [](var_name)
      return @data_def[var_name]
    end

    def symbol_call(symbol, *args, &block)
      if args.length == 0
        return var(symbol)
      elsif args.length == 2
        return data(symbol, *args)
      else
        raise DefinitionError, "Unknown use of keyword '#{var_name}' with args(#{args})."
      end
    end

    private

    def __process_bit_length(bit_length, name)
      bit_at = @bit_at
      case bit_length
      when Integer
        if @conditions.empty?
          @bit_at = @bit_at.add_imm(bit_length)
        else
          @bit_at = @bit_at.add_name(name)
        end
        return bit_at, Expression.immediate(bit_length)
      when Expression
        bit_length.variable_tokens.each do |token|
          if (token.value_var? || token.length_var?) && !__name_resolvable?(token.symbol)
            raise DefinitionError, "In #{name}, unsolvable variable #{symbol} is used."
          end
        end
        @bit_at = @bit_at.add_name(name)
        return bit_at, bit_length
      else
        raise DefinitionError, "Unknown type of bit_length (#{bit_length.class})."
      end
    end

    def __check_new_def_name(name)
      if name[0..1] == "__"
        raise DefinitionError, "Name that starts with '__' is system-reserved."
      end
      if @forbidden_method_names.include?(name)
        raise DefinitionError, "Name '#{name}' is already used as method name." +
          "You should chanege to other name."
      end
      if @data_def[name]
        raise DefinitionError, "Name #{name} is already defined." +
          "You should change to other name."
      end
    end

    def __name_resolvable?(name, structure=self)
      return structure[name] ||
        (structure.parent_structure && __name_resolvable?(name, structure.parent_structure))
    end
  end
end
