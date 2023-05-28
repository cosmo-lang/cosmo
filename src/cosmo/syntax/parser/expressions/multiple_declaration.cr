module Cosmo::AST::Expression
  class MultipleDeclaration < Base
    getter declarations : Array(VarDeclaration)

    def initialize(@declarations)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_multiple_declaration_expr(self)
    end

    def token : Token
      @declarations.first.token
    end

    def to_s(indent : Int = 0)
      "MultipleDeclaration<\n" +
      "  #{TAB * indent}declarations: [\n" +
      "    #{TAB * indent}#{@declarations.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}]\n" +
      "#{TAB * indent}>"
    end
  end
end
