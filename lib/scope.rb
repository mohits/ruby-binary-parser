module BinaryParser
  class Scope

    attr_reader :abstract_binary

    def initialize(structure_definition, abstract_binary, parent_scope=nil)
      @definition = structure_definition
      @abstract_binary = abstract_binary
      @parent_scope = parent_scope
      @data, @ebs, @ebl = {}, {}, {}
    end

    def names
      @definition.names.dup
    end

    def check_name_defined(name)
      raise UndefinedError, "Undefined data-name '#{name}'." unless @definition[name]
    end

    # * Unsatisfactory memorized method (little obfuscated? : need refactoring?)
    def load_var(name)
      return @parent_scope.load_var(name) if !@definition[name] && @parent_scope
      check_name_defined(name)
      case @definition[name]
      when StructureDefinition::DataDefinition
        return @data[name] ||= eval_bit_length(name) == 0 ? nil :
          @definition[name].klass.new(load_binary(name))
      when StructureDefinition::LoopDefinition
        return @data[name] ||= LoopList.new(@definition[name], load_binary(name), self)
      else
        raise ProgramAssertionError, "Unknown definition-class '#{@definition[name].class}'."
      end
    end

    def load_binary(name)
      check_name_defined(name)
      start  = eval_bit_position(name)
      length = eval_bit_length(name)
      begin
        return @abstract_binary.sub(:bit_index => start, :bit_length => length)
      rescue BadBinaryManipulationError => error
        raise ParsingError, "Cannot load binary of '#{name}'.\n" +
          "*** #{error.backtrace.first} ***\n#{error.message}\n"
      end
    end

    # * memorized method (little obfuscated? : need refactoring?)
    def eval_bit_position(name)
      check_name_defined(name)
      return @ebs[name] ||= @definition[name].bit_position.eval do |name|
        eval_bit_length(name)
      end
    end

    # * memorized method (little obfuscated? : need refactoring?)
    def eval_bit_length(name)
      check_name_defined(name)
      return @ebl[name] if @ebl[name]
      return @ebl[name] = 0 unless @definition[name].conditions.all? do |cond|
        cond.eval{|name| load_var(name)}
      end
      return @ebl[name] ||= @definition[name].bit_length.eval do |var_name|
        if var_name[0..1] == "__"
          bit_length_control_variable_resolution(name, var_name)
        else
          val = load_var(var_name)
          unless val
            raise ParsingError, "Variable '#{var_name}' assigned  to Nil is referenced" +
              "at the time of resolving bit_length of '#{var_name}'."
          end
          val.to_i
        end
      end
    end

    def bit_length_control_variable_resolution(name, var_name)
      if var_name == :__rest
        length = @abstract_binary.bit_length - eval_bit_position(name)
        raise ParsingError, "Binary is too short. (So, 'rest' is failed.)" if length < 0
        return length
      elsif var_name == :__position
        return eval_bit_position(name)
      elsif var_name[0..6] == "__LEN__"
        return eval_bit_length(var_name[7..(var_name.length - 1)].to_sym)
      else
        raise ProgramAssertionError, "Unknown Control-Variable '#{var_name}'."
      end
    end
    
    def eval_entire_bit_length
      return @definition.bit_at.eval do |name|
        eval_bit_length(name)
      end
    end
  end
end
