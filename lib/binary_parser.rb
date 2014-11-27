require "binary_parser/version"

module BinaryParser

  LIBRARY_ROOT_PATH = File.dirname(File.expand_path(File.dirname(__FILE__)))

  # load general class file
  GENERAL_CLASS_DIR = '/lib/binary_parser/general_class/'
  GENERAL_CLASS_FILES =
    ['binary_manipulate_function.rb',
     'abstract_binary',
     'expression.rb',
     'bit_position.rb',
     'condition.rb',
     'free_condition.rb',
     'buffered_stream.rb',
     'proxy.rb',
     'memorize.rb'
    ]

  GENERAL_CLASS_FILES.each do |path|
    require LIBRARY_ROOT_PATH + GENERAL_CLASS_DIR  + path
  end


  # load built-in template file
  class TemplateBase; end
  BUILT_IN_TEMPLATE_DIR = '/lib/binary_parser/built_in_template/'
  BUILT_IN_TEMPLATE_FILES =
    ['uint.rb',
     'flag.rb',
     'binary.rb',

    ]

  BUILT_IN_TEMPLATE_FILES.each do |path|
    require LIBRARY_ROOT_PATH + BUILT_IN_TEMPLATE_DIR  + path
  end
  

  # load library main file
  LIB_DIR = '/lib/binary_parser/'
  LIB_FILES =
    ['loop_list.rb',
     'while_list.rb',
     'scope.rb',
     'structure_definition.rb',
     'template_base.rb',
     'stream_template_base.rb',
     'nameless_template_maker.rb',
     'error.rb'
    ]

  LIB_FILES.each do |path|
    require LIBRARY_ROOT_PATH + LIB_DIR  + path
  end


  # load sub-built-in template file
  SUB_BUILT_IN_TEMPLATE_FILES =
    [
     'uint_n.rb',
     'bcd.rb',
    ]

  SUB_BUILT_IN_TEMPLATE_FILES.each do |path|
    require LIBRARY_ROOT_PATH + BUILT_IN_TEMPLATE_DIR  + path
  end

end
