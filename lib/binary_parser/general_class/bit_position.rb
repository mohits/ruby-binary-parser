module BinaryParser
  class BitPosition
    
    attr_reader :imm, :names

    def initialize(imm=0, names=[])
      @imm, @names = imm, names
    end

    def add_imm(length)
      return BitPosition.new(@imm + length, @names)
    end

    def add_name(name)
      return BitPosition.new(@imm, @names + [Expression.length_var(name)])
    end

    def eval(&name_eval_block)
      return @imm + @names.inject(0){|sum, name| sum + name_eval_block.call(name)}
    end
  end
end
