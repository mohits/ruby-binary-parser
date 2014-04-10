Ruby-Binary-Parser
===================
Ruby-Binary-Parser is Ruby Gem library providing DSL for parsing binary-data, such as Image files, Video files, etc.
Without operating bytes and bits complicatedly, you can parse and read binary-data *generically* and *abstractly*.


Description
-----------
This library can parse all kind of binary-data structures including non-fixed length of structures and nested structures.
For generic parsing, loop and condition(if) statement to define structures is provided in this library.
Of course, values of neighbor binary-data can be used as the other binary-data's specification of length.

Furthermore, this library handles all binary-data under the lazy evaluation.
So you can read required parts of a binary-data very quickly even if whole of the binary-data is too big, 


Notice
------
Currently, this library supports only READ of binary-data.
So you cannot WRITE binary-data directly with this library.


Usage
-----
Look at following examples to quickly understand how to use this library.

### Install ###
    $ gem install binary_parser


### Example 1  ###
Consider the following (temporary) binary structures which describe Image data.

<table style="margin-left:auto;margin-right:auto;">
  <tr><td colspan=4 style="text-align:center;">MyImage (non-fixed length)</td></tr>
  <tr style="background-color:lightsteelblue;">
	  <td style="width:150px;">Data Name</td>
		<td style="width:80px;">Type</td>
	  <td style="width:100px;">Bit Length</td>
		<td style="width:200px;">Number Of Replications</td>
	</tr>
  <tr>
	  <td>height</td>
		<td>UInt</td>
	  <td>8</td>
		<td>1</td>
	</tr>
  <tr>
	  <td>width</td>
		<td>UInt</td>
	  <td>8</td>
		<td>1</td>
	</tr>
  <tr>
	  <td>RGB color bit-map</td>
		<td>UInt</td>
	  <td>8 * 3</td>
		<td>'height' * 'width'</td>
	</tr>
  <tr>
	  <td>has date?</td>
		<td>Flag</td>
	  <td>1</td>
		<td>1</td>
	</tr>
  <tr>
	  <td>date</td>
		<td>MyDate</td>
	  <td>31</td>
		<td>'has date?' is 1 => 1<br>else => 0</td>
	</tr>
</table>


<table style="margin-left:auto;margin-right:auto;">
  <tr><td colspan=4 style="text-align:center;">MyDate (31 bit)</td></tr>
  <tr style="background-color:lightsteelblue;">
	  <td style="width:150px;">Data Name</td>
		<td style="width:80px;">Type</td>
	  <td style="width:100px;">Bit Length</td>
		<td style="width:200px;">Number Of Replications</td>
	</tr>
  <tr>
	  <td>year</td>
		<td>UInt</td>
	  <td>13</td>
		<td>1</td>
	</tr>
  <tr>
	  <td>month</td>
		<td>UInt</td>
	  <td>9</td>
		<td>1</td>
	</tr>
  <tr>
	  <td>day</td>
		<td>UInt</td>
	  <td>9</td>
		<td>1</td>
	</tr>
</table>

You can define MyImage structure in ruby program as following code.


    require 'binary_parser'

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

        TIMES var(:height), :i do
          TIMES var(:width), :j do
            data :R, UInt, 8
            data :G, UInt, 8
            data :B, UInt, 8
          end
        end

        data :has_date, Flag, 1
        IF cond(:has_date){|v| v.flagged?} do
          data :date, MyDate, 31
        end
      end
    end


And then you can parse and read binay-data of MyImage as follows.

    File.open('my_image.bin', 'rb') do |f|
      image = MyImage.new(f.read)
      print "Image size: #{image.height.to_i}x#{image.width.to_i}\n"
      ul = image.i[0].j[0]
      print "RGB color at the first is (#{ul.R.to_i}, #{ul.G.to_i}, #{ul.B.to_i})\n"
      print "Image date: #{image.date.to_date}\n"
    end


If 'my_image.bin' is binary-data-file of [0x02, 0x02, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0x9f, 0x78, 0x08, 0x03], 
you can get output as follows.

    Image size: 2x2
    RGB color at the first is (231, 57, 98)
    Image date: 2014-04-03


For your information, you can dump all binary-data's information as follows.

    File.open('my_image.bin', 'rb') do |f|
      image = MyImage.new(f.read)
      image.show(true)
    end


### Example 2  ###
You can also define other structures as follows.

    class DefExample < BinaryParser::TemplateBase
      Def do
        data :loop_byte_length, UInt, 8

        # Loop until 'loop_byte_length' * 8 bits are parsed.
        SPEND var(:loop_byte_length) * 8, :list do
          data :length, UInt,   8
          # Specifying length by neigbor value.
          data :data,   Binary, var(:length) * 8
        end

        data :v1, UInt, 8
        data :v2, UInt, 8

        # Number of Condition variables is arbitary. 
        IF cond(:v1, :v2){|v1, v2| v1.to_i == v2.to_i} do
          # +, -, *, / is available for var. (Order of [Integer op Variable] is NG.)
          data :v3, UInt, (var(:v1) + var(:v2)) * 8
        end
      end
    end

Check this definition by giving some binary-data and calling show method as follows. 

    i = DefExample.new([0x05, 0x01, 0xff, 0x02, 0xff, 0xff, 0x01, 0x01, 0x01, 0x01].pack("C*"))
    i.show(true)


### Example 3  ###
If you want to operate Stream-data, StreamTemplateBase class is useful. Define stream as follows.

    class StreamExample < BinaryParser::StreamTemplateBase
      # Stream which consists of every 4 byte binary-data.
      Def(4) do
        data :data1, UInt,   8
        data :data2, Binary, 24
      end
    end

And then, get structures from the stream as follows.

    File.open('my_image.bin', 'rb') do |f|
      stream = StreamExample.new(f)
      packet = stream.get_next
      puts "data1: #{packet.data1.to_i}, data2: #{packet.data2.to_s}"
      stream.get_next.show(true)
    end

StreamTemplateBase has many useful methods to choose structures from the stream.
If you want to know detail of these methods, please read documentation or concerned source-files.


Documentation
--------------
I'm sorry, but only RDoc (auto-generated documentation) is now available.
For example, you can read RDoc on web browser by following operations.

    $ gem install binary_parser
    $ gem server
    Server started at http://0.0.0.0:8808

Access shown address by web browser.


Versions
--------
1.0.0 April 6, 2014