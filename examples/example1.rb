require File.dirname(File.expand_path(File.dirname(__FILE__))) + "/lib/binary_parser.rb"

class MyDate < BinaryParser::TemplateBase
  require 'date'

  Def do
    data :year,  UInt, 13
    data :month, UInt, 9
    data :day,   UInt, 9
  end

  def to_date
    return Date.new(year.to_i, month.to_i, day.to_i)
  end
end

class MyImage < BinaryParser::TemplateBase
  Def do
    data :height, UInt, 8
    data :width,  UInt, 8

    # Loop statement
    TIMES var(:height), :i do
      TIMES var(:width), :j do
        data :R, UInt, 8
        data :G, UInt, 8
        data :B, UInt, 8
      end
    end

    data :has_date, Flag, 1

    # Condition statement
    # * If you want to check whether variable-name is valid, alternative expression
    #     IF cond(:has_date){|v| v.on?} do ~ end
    #   is also available.
    IF E{ has_date.on? } do
      data :date, MyDate, 31
    end
  end
end

bin = [0x02, 0x02, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0x9f, 0x78, 0x08, 0x03]

image = MyImage.new(bin.pack("C*"))
print "Image size: #{image.height}x#{image.width}\n"
ul = image.i[0].j[0]
print "RGB color at the first is (#{ul.R}, #{ul.G}, #{ul.B})\n"
print "Image date: #{image.date.to_date}\n"
