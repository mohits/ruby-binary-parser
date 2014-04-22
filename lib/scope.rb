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
        eval_bit_length(name) == 0 ? nil : @definition[name].klass.new(load_binary(name))
      when StructureDefinition::LoopDefinition
        LoopList.new(@definition[name], load_binary(name), self)
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
      return @definition[name].bit_position.eval do |name|
        eval_bit_length(name)
      end
    end

    # * memorized method (little obfuscated? : need refactoring?)
    def eval_bit_length(name)
      check_name_defined(name)
      unless @definition[name].conditions.all?{|cond| cond.eval{|name| load_var(name)}}
        return 0
      end
      return eval(name, @definition[name].bit_length)
    end

    def eval(name, target)
      target.eval do |token|
        if token.control_var?
          bit_length_control_variable_resolution(name, token.symbol)
        elsif token.length_var?
          eval_bit_length(token.symbol)
        elsif token.value_var?
          val = load_var(token.symbol)
          unless val
            raise ParsingError, "Variable '#{token.symbol}' assigned  to Nil is referenced" +
              "at the time of resolving bit_length of '#{name}'."
          end
          val.to_i
        end
      end
    end

    def bit_length_control_variable_resolution(name, symbol)
      if symbol == :rest
        length = @abstract_binary.bit_length - eval_bit_position(name)
        raise ParsingError, "Binary is too short. (So, 'rest' is failed.)" if length < 0
        return length
      elsif symbol == :position
        return eval_bit_position(name)
      else
        raise ProgramAssertionError, "Unknown Control-Variable '#{symbol}'."
      end
    end
    
    def eval_entire_bit_length
      return @definition.bit_at.eval do |name|
        eval_bit_length(name)
      end
    end
  end
end
