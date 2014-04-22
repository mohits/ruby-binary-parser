module BinaryParser
  class WhileList < LoopList
    
    attr_reader :bit_length
    
    def initialize(definition, abstract_binary, parent_scope, name)
      parsed_length = 0
      list, rest_binary = [], abstract_binary
      while continue?(definition, rest_binary, parent_scope, name)
        template = definition.klass.new(rest_binary, parent_scope)
        if template.structure_bit_length == 0
          raise ParsingError, "0 bit-length repetition happens. This means infinite loop."
        end
        parsed_length += template.structure_bit_length
        rest_binary = rest_binary.sub(:bit_index => template.structure_bit_length)
        list << template
      end
      @list, @bit_length = list, parsed_length
    end

    def continue?(definition, rest_binary, parent_scope, name)
      definition.loop_condition.eval do |token|
        if token.nextbits_var?
          TemplateBase.new(rest_binary.sub(:bit_length => token.length)).to_i
        else
          parent_scope.token_eval(token, name)
        end
      end
    end
  end
end
