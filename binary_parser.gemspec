# -*- mode: ruby; coding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'binary_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "binary_parser"
  spec.version       = BinaryParser::VERSION
  spec.authors       = ["rokugats(u)"]
  spec.email         = ["sasasawada@gmail.com"]
  spec.summary       = "An elegant DSL library for parsing binary-data."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.description = <<-END
This library can parse all kind of binary-data structures including non-fixed length of structures and nested structures.
For generic parsing, loop and condition(if) statement to define structures is provided in this library.
Of course, values of neighbor binary-data can be used as the other binary-data's specification of length.

Furthermore, this library handles all binary-data under the lazy evaluation.
So you can read required parts of a binary-data very quickly even if whole of the binary-data is too big, 
END

end
