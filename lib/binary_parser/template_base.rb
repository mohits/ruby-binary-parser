module BinaryParser
  class TemplateBase

    include BuiltInTemplate

    def self.def_structure(parent_structure=nil, &definition_proc)
      @structure_def = StructureDefinition.new(instance_methods, parent_structure, &definition_proc)
      @structure_def.names.each do |name|
        def_var_method(name)
      end
    end

    def self.def_var_method(name)
      define_method(name){|&block| load(name, &block) }
    end

    def self.Def(parent_structure=nil, &definition_proc)
      def_structure(parent_structure, &definition_proc)
    end
    
    def self.structure
      return @structure_def ||= StructureDefinition.new
    end

    def initialize(binary, parent_scope=nil)
      @scope = Scope.new(self.class.structure, convert_into_abstract_binary(binary), parent_scope)
    end

    def load(name, &block)
      if block
        case block.arity
        when 0
          @scope.load_var(name).instance_eval(&block)
        when 1
          block.call(@scope.load_var(name))
        end
      else
        @scope.load_var(name)
      end
    end

    def convert_into_abstract_binary(object)
      return object if object.is_a?(AbstractBinary)
      if object.is_a?(String) && object.encoding == Encoding::BINARY
        return AbstractBinary.new(object)
      end
      raise BadManipulationError, "Argument should be AbstractBinary or BINAY String."
    end

    def [](name)
      @scope.load_var(name)
    end

    def names
      @scope.names
    end

    # Convert held binary into unsigned integer.
    # Special case:
    #   If held binary's length is 0, this method throws BadBinaryManipulationError.
    def to_i
      @scope.abstract_binary.to_i
    end

    # Convert held binary into string encoded in Encoding::BINARY.
    # Special case:
    #   If held binary's length or start position isn't a multiple of 8,
    #   this method throws BadBinaryManipulationError.
    def to_s
      @scope.abstract_binary.to_s
    end

    # Convert held binary into character-numbers.
    # Example: If held binary is "ABC" in ascii, this returns [0x41, 0x42, 0x43].
    # Special case:
    #   If held binary's length or start position isn't a multiple of 8,
    #   this method throws BadBinaryManipulationError.
    def to_chars
      @scope.abstract_binary.to_chars
    end

    # Real length(bit) of held binary
    def binary_bit_length
      @scope.abstract_binary.bit_length
    end

    # Structure-specified length(bit) of binary.
    # Special case:
    #   If held binary's length is too short to calculate structure-specified length,
    #   this method throws ParsingError.
    def structure_bit_length
      @scope.eval_entire_bit_length
    end

    # Whether real length of held binary is NOT smaller than structure-specified length of binary.
    # Special case:
    #   If held binary's length is too short to calculate structure-specified length,
    #   this method throws ParsingError.
    def hold_enough_binary?
      structure_bit_length <= binary_bit_length
    end

    # Whether real length of held binary is equal to structure-specified length of binary.
    # Special case:
    #   If held binary's length is too short to calculate structure-specified length,
    #   this method throws ParsingError.
    def hold_just_binary?
      structure_bit_length == binary_bit_length
    end

    # String that describes this object.
    #   * If you want to print some of this content-description in 'show' method,
    #     override this method.
    def content_description
      ""
    end

    # Print all elements' information.
    # Args:
    #   recursively => Whether print recursively or not. Default is false.
    #   out         => Print target. Default is STDOUT.
    def show(recursively=false, out=STDOUT, depth=0)
      max_name_length = names.inject(5){|max_len, name| [max_len, name.length].max}
      if names.size > 0
        out.puts "#{" " * (depth*2)}*#{"-" * 80}"
      end
      names.each do |name|
        out.puts sprintf("#{" " * (depth*2)}%-#{max_name_length}s  Pos: %6s  Len: %6s  Type: %10s  Cont: %s",
                         name.to_s,
                         @scope.eval_bit_position(name),
                         @scope.eval_bit_length(name),
                         self[name].class.name.split("::").last,
                         self[name] ? self[name].content_description : "Nil")
        self[name].show(true, out, depth + 1) if recursively && self[name]
      end
    end
  end
end
