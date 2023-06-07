module Cosmo::AST::Expression
  class MultipleAssignment < Base
    getter assignments : Array(VarAssignment | PropertyAssignment)

    def initialize(@assignments)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_multiple_assignment_expr(self)
    end

    def token : Token
      @assignments.first.token
    end

    def to_s(indent : Int = 0)
      "MultipleAssignment<\n" +
      "  #{TAB * indent}assignments: [\n" +
      "    #{TAB * indent}#{@assignments.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}]\n" +
      "#{TAB * indent}>"
    end
  end
end
