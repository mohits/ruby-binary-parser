module BinaryParser
  class StreamTemplateBase
    include BuiltInTemplate

    def self.def_stream(byte_length, &definition_proc)
      @byte_length = byte_length
      used_method_names = NamelessTemplate.instance_methods + Scope.instance_methods
      @structure = StructureDefinition.new(used_method_names, &definition_proc)
    end

    def self.Def(byte_length, &definition_proc) def_stream(byte_length, &definition_proc) end

    def self.get_stream_definition
      raise BadManipulationError, "Stream is undefined." unless @byte_length && @structure 
      return @byte_length, @structure
    end

    def initialize(binary_stream, filters=[])
      @binary_stream = binary_stream
      @filters = filters
    end

    # Add fileter to instance (not disruptive)
    # return: new instance which has filter
    def filter(&filter_proc)
      raise BadManipulationError, "Filter Proc isn't given." unless filter_proc
      return self.class.new(@binary_stream, @filters + [filter_proc])
    end

    # Get next element from binary-stream.
    # If instance has filters, the unsatisfied element is to be abandoned
    #  and recursively returns next element.
    # Special cases:
    #   (1) If rest of binary-stream's length is 0, this method returns nil.
    #   (2) If rest of binary-stream's length is shorter than required,
    #       this method throws BadBinaryManipulationError.
    def get_next
      begin
        if @lookahead
          scope, @lookahead = @lookahead, nil
        else
          byte_length, structure = self.class.get_stream_definition
          binary = @binary_stream.read(byte_length)
          return nil unless binary
          if binary.length < byte_length
            raise ParsingError, "Stream's rest binary length" + 
              "(#{binary.length} byte) is shorter than required length (#{byte_length} byte)."
          end
          abstract_binary = AbstractBinary.new(binary)
          scope = Scope.new(structure, abstract_binary)
        end
      end until @filters.all?{|filter| filter.call(scope)}
      return NamelessTemplate.new(scope)
    end

    # Remove elements until finding element which fullfils proc-condition or reaching end of stream.
    # return: array of removed elements
    #
    # Concrete example:
    #   If stream has [F1, F2, T3, F4, ...] and given cond_proc is Proc.new{|a| a == Tx},
    #   seek_top(&cond_proc) returns array of [F1, F2] and then stream has [T3, F4, ...].
    #   In the same way, (1) [T1, F2, ...] => return: [],       stream: [T1, F2, ...]
    #                    (2) [F1, F2]      => return: [F1, F2], stream: [] (end)
    #                    (3) [] (end)      => return: [],       stream: [] (end)
    def seek_top(&cond_proc)
      raise BadManipulationError, "Condition Proc isn't given." unless cond_proc
      abandoned = []
      until @lookahead && cond_proc.call(@lookahead)
        if @lookahead
          abandoned << @lookahead
          @lookahead = nil
        end
        return abandoned unless rest?
        @lookahead = get_next
      end
      return abandoned
    end

    # Get sequence by specifing head-condition.
    # Concrete example:
    #   If stream has [F1, T2, F3, F4, T5, ...] and given cond_proc is Proc.new{|a| a == Tx},
    #   get_sequence(&cond_proc) returns array of [T2, F3, F4] and then stream has [T5, ...].
    #
    #   In the same way, (1) [T1, F2, T3, ...] => return: [T1, F2], stream: [T3, ...]
    #                    (2) [T1, T2, F3, ...] => return: [T1],     stream: [T2, F3, ...]
    #                    (3) [T1, F2]          => return: [],       stream: [] (end)
    #                    (4) [F1, F2]          => return: [],       stream: [] (end)
    #                    (5) [] (end)          => return: [],       stream: [] (end)
    #
    #   * But if option-arg "allow_incomplete_sequence" is set as true, above example of (3) is
    #                        [T1, F2, F3, F4]  => return: [T1, F2, F3, F4], stream: [] (end)
    def get_sequence(allow_incomplete_sequence = false, &cond_proc)
      raise BadManipulationError, "Condition Proc isn't given." unless cond_proc
      seek_top(&cond_proc)
      return [] unless rest?
      res = [get_next] + seek_top(&cond_proc)
      return [] unless rest? || allow_incomplete_sequence
      return res
    end

    # Accumulate elements
    # Concrete example:
    #   If stream has [1, 2, 3, 4, 5, ...] and given reduce_proc is Proc.new{|acc, a| acc + a},
    #   accumulate(0, 6, &reduce_proc) returns array of [1, 2, 3] and then stream has[4, 5, ...].
    #
    # Special case: If enough elements don't remain, this method returns nil.
    #   Example: [1, 2, 3], accumulate(0, 7, &reduce_proc) => return: nil, stream: [] (end)
    def accumulate(init_amount, dest_amount, &reduce_proc)
      raise BadManipulationError, "Reduce Proc isn't given." unless reduce_proc
      accumulation, amount = [], init_amount
      while amount < dest_amount
        return nil unless rest?
        accumulation << get_next
        amount = reduce_proc.call(amount, accumulation.last)
      end
      return accumulation
    end

    # Check whether binary-stream remains or not.
    def rest?
      return @lookahead || !@binary_stream.eof?
    end

    # Simply close binary-stream.
    def close
      @binary_stream.close
    end
  end
end
