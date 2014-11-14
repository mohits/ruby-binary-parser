module BinaryParser

  # User do Invalid Parsing Definition.
  DefinitionError = Class.new(StandardError)

  # User do Bad Manipulation.
  BadManipulationError = Class.new(StandardError)

  # Undefined Data is referenced.
  UndefinedError = Class.new(StandardError)

  # Invalid Binary Pattern is parsed.
  ParsingError = Class.new(StandardError)

  # Invalid Binary Manipulation is done.
  BadBinaryManipulationError = Class.new(StandardError)

  # Assertion Error.
  # If this error occurs in regular use, probably this library(binary_parser) has Bugs.
  ProgramAssertionError = Class.new(StandardError)
end
