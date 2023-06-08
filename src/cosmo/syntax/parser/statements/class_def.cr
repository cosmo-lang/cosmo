module Cosmo::AST::Statement
  class ClassDef < Base
    getter identifier : Token
    # getter parameters : Array(Expression::Parameter) # generics?
    getter body : Block
    getter visibility : Visibility
    getter superclass : Expression::Var?
    getter mixins : Array(Expression::Var)

    def initialize(@identifier, @body, @visibility, @superclass, @mixins)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_class_def_stmt(self)
    end

    def token : Token
      @identifier
    end

    def to_s(indent : Int = 0)
      "ClassDef<\n" +
      "  #{TAB * indent}identifier: #{@identifier.value.to_s},\n" +
      "  #{TAB * indent}body: #{@body.to_s(indent + 1)}\n" +
      "  #{TAB * indent}visibility: #{@visibility.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
