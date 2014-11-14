module BinaryParser
  class LoopList
    include Enumerable

    def initialize(definition, abstract_binary, parent_scope)
      list, rest_binary = [], abstract_binary
      while rest_binary.bit_length > 0
        template = definition.klass.new(rest_binary, parent_scope)
        if template.structure_bit_length == 0
          raise ParsingError, "0 bit-length repetition happens. This means infinite loop."
        end
        rest_binary = rest_binary.sub(:bit_index => template.structure_bit_length)
        list << template
      end
      @list = list
    end

    def each(&block)
      @list.each(&block)
    end

    def [](index)
      unless @list[index]
        raise BadManipulationError, "Index is out of bounds. List size is #{@list.size}." +
          "You accessed list[#{index}]." 
      end
      return @list[index]
    end

    def size
      return @list.size
    end

    alias_method :length, :size

    # String that describes this object.
    def content_description
      "list with #{size} elements"
    end

    # Print all elements' information.
    # Args:
    #   recursively => Whether print recursively or not. Default is false.
    #   out         => Print target. Default is STDOUT.
    def show(recursively=false, out=STDOUT, depth=0)
      @list.each_with_index do |element, i|
        out.puts sprintf(" " * (depth * 2) + "%-5s", "[#{i}]")
        element.show(true, out, depth + 1) if recursively
      end
    end
  end
end

