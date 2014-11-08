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

```ruby
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
```

And then you can parse and read binay-data of MyImage as follows.

```ruby
File.open('my_image.bin', 'rb') do |f|
  image = MyImage.new(f.read)
  puts "Image size: #{image.height}x#{image.width}"
  ul = image.i[0].j[0]
  puts "RGB color at the first is (#{ul.R}, #{ul.G}, #{ul.B})"
  puts "Image date: #{image.date.to_date}"
end
```

If 'my_image.bin' is binary-data-file of [0x02, 0x02, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0xe7,0x39,0x62, 0x00,0x00,0x00, 0x9f, 0x78, 0x08, 0x03], 
you can get output as follows.

    Image size: 2x2
    RGB color at the first is (231, 57, 98)
    Image date: 2014-04-03


For your information, you can dump all binary-data's information as follows.

```ruby
File.open('my_image.bin', 'rb') do |f|
  image = MyImage.new(f.read)
  image.show(true)
end
```

### Example 2  ###
You can also define other structures as follows.

```ruby
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
```

You can check this definition by giving some binary-data and calling show method as follows. 

```ruby
binary = [0x05, 0x01, 0xff, 0x02, 0xff, 0xff, 0x01, 0x01, 0x01, 0x01].pack("C*")
i = DefExample.new(binary)
i.show(true)
```

Output for above checking-code is shown below.

```
*--------------------------------------------------------------------------------
loop_byte_length  Pos:      0  Len:      8  Type:       UInt  Cont: 5
list              Pos:      8  Len:     40  Type:   LoopList  Cont: list with 2 elements
  [0]
    *--------------------------------------------------------------------------------
    length  Pos:      0  Len:      8  Type:       UInt  Cont: 1
    data    Pos:      8  Len:      8  Type:     Binary  Cont: [0xff]
  [1]
    *--------------------------------------------------------------------------------
    length  Pos:      0  Len:      8  Type:       UInt  Cont: 2
    data    Pos:      8  Len:     16  Type:     Binary  Cont: [0xff, 0xff]
v1                Pos:     48  Len:      8  Type:       UInt  Cont: 1
v2                Pos:     56  Len:      8  Type:       UInt  Cont: 1
v3                Pos:     64  Len:     16  Type:       UInt  Cont: 257
```


### Example 3  ###
If you want to operate Stream-data, StreamTemplateBase class is useful. Define stream as follows.

```ruby
class StreamExample < BinaryParser::StreamTemplateBase
  # Stream which consists of every 4 byte binary-data.
  Def(4) do
    data :data1, UInt,   8
    data :data2, Binary, 24
  end
end
```

And then, get structures from the stream as follows.

```ruby
File.open('my_image.bin', 'rb') do |f|
  stream = StreamExample.new(f)
  packet = stream.get_next
  puts "data1: #{packet.data1}, data2: #{packet.data2}"
  stream.get_next.show(true)
end
```

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
1.0.0 April    6, 2014  
1.2.0 November 7, 2014
