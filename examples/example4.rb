require File.dirname(File.expand_path(File.dirname(__FILE__))) + "/lib/binary_parser.rb"

class UseUInt8 < BinaryParser::TemplateBase
  Def do
    SPEND 24, :spends, UInt8
  end
end

bin = [0x01, 0x02, 0x03].pack("C*")
UseUInt8.new(bin).show(true)
