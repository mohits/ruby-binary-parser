module BinaryParser
  module NamelessTemplateMaker
    def self.new(parent_structure=nil, structure_definition_proc)
      Class.new(TemplateBase) do
        Def(parent_structure, &structure_definition_proc)
      end
    end
  end
end
