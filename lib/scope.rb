module BinaryParser
  class Scope
    include Memorize.one_arg_method(:load_var, :eval_bit_position, :eval_bit_length)

    attr_reader :abstract_binary

    def initialize(structure_definition, abstract_binary, parent_scope=nil)
      @definition = structure_definition
      @abstract_binary = abstract_binary
      @parent_scope = parent_scope
    end

    def names
      @definition.names.dup
    end

    def check_name_defined(name)
      raise UndefinedError, "Undefined data-name '#{name}'." unless @definition[name]
    end

    def load_var(name)
      return @parent_scope.load_var(name) if !@definition[name] && @parent_scope
      check_name_defined(name)
      case @definition[name]
      when StructureDefinition::DataDefinition
        eval_bit_length(name) == 0 ? nil : @definition[name].klass.new(load_binary(name))
      when StructureDefinition::LoopDefinition
        LoopList.new(@definition[name], load_binary(name), self)
      when StructureDefinition::WhileDefinition
        sub_binary = @abstract_binary.sub(:bit_index => eval_bit_position(name))
        WhileList.new(@definition[name], sub_binary, self, name)
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

    def preview_as_integer(start_pos, length)
      sub_binary = @abstract_binary.sub(:bit_index => start_pos, :bit_length => length)
      TemplateBase.new(sub_binary).to_i
    end

    def eval_bit_position(name)
      check_name_defined(name)
      return eval(@definition[name].bit_position, nil)
    end

    def eval_bit_length(name)
      check_name_defined(name)
      unless @definition[name].conditions.all?{|cond| eval(cond, name)}
        return 0
      end
      return eval(@definition[name].bit_length, name)
    end
  
    def eval_entire_bit_length
      eval(@definition.bit_at, nil)
    end

    def eval(target, name)
      target.eval do |token|
        token_eval(token, name)
      end
    end

    def token_eval(token, name)
      if token.control_var?
        bit_length_control_variable_resolution(name, token.symbol)
      elsif token.nextbits_var?
        preview_as_integer(eval_bit_position(name), token.length)
      elsif token.length_var?
        eval_bit_length(token.symbol)
      elsif token.value_var?
        unless val = load_var(token.symbol)
          raise ParsingError, "Variable '#{token.symbol}' assigned  to Nil is referenced" +
            "at the time of resolving '#{name}'."
        end
        val.to_i
      end
    end
    
    def bit_length_control_variable_resolution(name, symbol)
      if symbol == :rest
        length = @abstract_binary.bit_length - eval_bit_position(name)
        raise ParsingError, "Binary is too short. (So, 'rest' is failed.)" if length < 0
        return length
      elsif symbol == :position
        return eval_bit_position(name)
      elsif symbol == :non_fixed
        return load_var(name).bit_length
      else
        raise ProgramAssertionError, "Unknown Control-Variable '#{symbol}'."
      end
    end
  end
end
