module BinaryParser
  class StructureDefinition
    
    DataDefinition  = Struct.new(:bit_position, :bit_length, :conditions, :klass)
    LoopDefinition  = Struct.new(:bit_position, :bit_length, :conditions, :structure)

    attr_reader :parent_structure, :bit_at, :names

    def initialize(method_names=[], parent_structure=nil, &init_proc)
      @method_names = method_names
      @parent_structure = parent_structure
      @bit_at = BitPosition.new     
      @data_def, @var = {}, {}
      @conditions, @names = [], []
      instance_eval(&init_proc) if init_proc
    end

    def data(name, klass, bit_length)
      check_new_def_name(name)
      unless klass.ancestors.include?(TemplateBase)
        raise DefinitionError, "Class #{klass} should be TemplateBase."
      end
      bit_at, bit_length = process_bit_length(bit_length, name)
      @data_def[name] = DataDefinition.new(bit_at, bit_length, @conditions.dup, klass)
      @names << name
    end

    def SPEND(bit_length, name,  &block)
      check_new_def_name(name)
      bit_at, bit_length = process_bit_length(bit_length, name)
      used_method_names = NamelessTemplate.instance_methods + Scope.instance_methods
      structure = StructureDefinition.new(used_method_names, self, &block)
      @data_def[name] = LoopDefinition.new(bit_at, bit_length, @conditions.dup, structure)
      @names << name
    end

    def TIMES(times, name, &block)
      check_new_def_name(name)
      structure = StructureDefinition.new(Scope.instance_methods, self, &block)
      if structure.bit_at.names.empty?
        bit_at, bit_length = process_bit_length(times * structure.bit_at.imm, name)
        @data_def[name] = LoopDefinition.new(bit_at, bit_length, @conditions.dup, structure)
      else
        bit_length = Expression.new([0])
        structure.bit_at.names.each do |bit_at_depending_name|
          depending_length_exp = structure[bit_at_depending_name].bit_length
          depending_length_exp.variables.each do |var_name|
            if structure[var_name]
              raise DefinitionError, "In '#{name}', same level variable #{var_name} is referenced." + 
                "*** TIMES's inner structure's bit-length must be always same." +
                "In other words, that bit-length must not rely on same level variables. ***"
            end
          end
          bit_length += depending_length_exp
        end
        bit_at, bit_length = process_bit_length(bit_length * times, name)
        @data_def[name] = LoopDefinition.new(bit_at, bit_length, @conditions.dup, structure)
      end
      @names << name
    end

    def IF(condition, &block)
      @conditions.push(condition)
      block.call
      @conditions.pop
    end

    def check_new_def_name(name)
      if name[0..1] == "__"
        raise DefinitionError, "Name that starts with '__' is system-reserved."
      end
      if @method_names.include?(name)
        raise DefinitionError, "Name '#{name}' is already used as method name." +
          "You should chanege to other name."
      end
      if @data_def[name]
        raise DefinitionError, "Name #{name} is already defined." +
          "You should change to other name."
      end
    end

    def name_solvable?(name, structure=self)
      return structure[name] ||
        (structure.parent_structure && name_solvable?(name, structure.parent_structure))
    end

    def cond(*var_names, &condition_proc)
      var_names.each do |var_name|
        unless name_solvable?(var_name)
          raise DefinitionError, "As condition variable, unsolvable variable #{var_name} is used."
        end
      end
      return Condition.new(*var_names, &condition_proc)
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
      unless name_solvable?(var_name)
        raise DefinitionError, "Unsolvable variable #{var_name} is used."
      end
      return Expression.new([var_name])
    end

    def len(var_name)
      unless name_solvable?(var_name)
        raise DefinitionError, "Unsolvable variable #{var_name} is used."
      end
      symbol = ("__LEN__" + var_name.to_s).to_sym
      return Expression.new([symbol])
    end

    def position
      return Expression.new([:__position])
    end

    def rest
      return Expression.new([:__rest])
    end

    def [](var_name)
      return @data_def[var_name]
    end

    private

    def process_bit_length(bit_length, name)
      bit_at = @bit_at
      case bit_length
      when Integer
        if @conditions.empty?
          @bit_at = @bit_at.add_imm(bit_length)
        else
          @bit_at = @bit_at.add_name(name)
        end
        return bit_at, Expression.new([bit_length])
      when Expression
        bit_length.variables.reject{|s| s[0..1] == "__"}.each do |symbol|
          unless name_solvable?(symbol)
            raise DefinitionError, "In #{name}, unsolvable variable #{symbol} is used."
          end
        end
        @bit_at = @bit_at.add_name(name)
        return bit_at, bit_length
      else
        raise DefinitionError, "Unknown type of bit_length (#{bit_length.class})."
      end
    end
  end
end
