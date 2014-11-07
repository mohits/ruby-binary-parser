require File.dirname(File.expand_path(File.dirname(__FILE__))) + "/lib/binary_parser.rb"

class DefExample < BinaryParser::TemplateBase
  Def do
    data :loop_byte_length, UInt, 8

    # Loop until 'loop_byte_length' * 8 bits are parsed.
    SPEND var(:loop_byte_length) * 8, :list do

      data :length, UInt,   8

      # You can specify length by neigbor value.
      data :data,   Binary, var(:length) * 8
    end

    data :v1, UInt, 8
    data :v2, UInt, 8

    # Number of Condition variables is arbitary. 
    IF cond(:v1, :v2){|v1, v2| v1 == v2} do

      # +, -, *, / is available to specify length with variable.
      data :v3, UInt, 8 * (var(:v1) + var(:v2))
    end
  end
end

i = DefExample.new([0x05, 0x01, 0xff, 0x02, 0xff, 0xff, 0x01, 0x01, 0x01, 0x01].pack("C*"))
i.show(true)
