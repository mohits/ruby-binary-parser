module BinaryParser
  class StreamTemplateBase
    include BuiltInTemplate

    def self.def_stream(byte_length, buffer_num=10000, &definition_proc)
      @byte_length = byte_length
      @buffer_size = buffer_num * byte_length
      @template = NamelessTemplateMaker.new(definition_proc)
    end

    def self.Def(byte_length, buffer_num=10000, &definition_proc)
      def_stream(byte_length, buffer_num, &definition_proc)
    end

    def self.get_template
      raise BadManipulationError, "Structure is undefined." unless @template
      return @template
    end

    def self.get_byte_length
      raise BadManipulationError, "Byte-length is undefined." unless @byte_length
      return @byte_length
    end

    def self.get_buffer_size
      raise BadManipulationError, "Buffer-size is undefined." unless @buffer_size
      return @buffer_size
    end

    def initialize(binary_stream, filters=[])
      case binary_stream
      when BufferedStream
        @buffered_binary_stream = binary_stream
      else
        @buffered_binary_stream = BufferedStream.new(binary_stream, self.class.get_buffer_size)
      end
      @filters = filters
    end

    # Add fileter to instance (not disruptive)
    # return: new instance which has filter
    def filter(&filter_proc)
      raise BadManipulationError, "Filter Proc isn't given." unless filter_proc
      return self.class.new(@buffered_binary_stream, @filters + [filter_proc])
    end

    # Get next element from binary-stream.
    # If instance has filters, the unsatisfied element is to be abandoned
    #  and recursively returns next element.
    # Special cases:
    #   (1) If rest of binary-stream's length is 0, this method returns nil.
    #   (2) If rest of binary-stream's length is shorter than required,
    #       this method throws ParsingError.
    def get_next
      return take_lookahead || filtered_simply_get_next(@filters)
    end

    def non_proceed_get_next
      @lookahead ||= get_next
    end

    def take_lookahead
      res, @lookahead = @lookahead, nil
      return res
    end

    def filtered_simply_get_next(filters)
      begin
        structure = simply_get_next
        return nil unless structure
      end until filters.all?{|filter| filter.call(structure)}
      return structure
    end

    def simply_get_next
      return nil unless binary = next_binary
      self.class.get_template.new(binary)
    end

    def next_binary
      binary = @buffered_binary_stream.read(self.class.get_byte_length)
      if binary && binary.length < self.class.get_byte_length
        raise ParsingError, "Stream's rest binary length" + 
          "(#{binary.length} byte) is shorter than required length (#{self.class.get_byte_length} byte)."
      end
      return binary
    end

    # Take n elements from stream. Behave like calling #get_next n times.
    # Special cases:
    #  (1) If n elements do NOT exist in stream (only m elements exist), 
    #      this method take m (< n) elements from stream.
    def read(n)
      res = []
      n.times do
        if rest?
          res << get_next
        else
          break
        end
      end
      return res
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
      until !rest? || cond_proc.call(non_proceed_get_next)
        abandoned << take_lookahead
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
      non_proceed_get_next
    end

    def eof?
      !rest?
    end

    def eof
      eof?
    end
      
    # Simply close binary-stream.
    def close
      @buffered_binary_stream.close
    end
  end
end
