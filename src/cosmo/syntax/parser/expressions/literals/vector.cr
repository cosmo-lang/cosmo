module Cosmo::AST::Expression
  class VectorLiteral < Base
    getter token : Token
    getter values : Array(Base)

    def initialize(@values, @token)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_vector_literal_expr(self)
    end

    def to_s(indent : Int = 0)
      "Literal<[\n" +
      "  #{TAB * indent}#{@values.map(&.to_s(indent + 2)).join(",\n#{TAB * (indent + 1)}")}\n" +
      "#{TAB * indent}]>"
    end
  end
end
