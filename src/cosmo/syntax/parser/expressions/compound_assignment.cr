module Cosmo::AST::Expression
  class CompoundAssignment < Base
    getter name : Var | Index | Access
    getter operator : Token
    getter value : Base

    def initialize(@name, @operator, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_compound_assignment_expr(self)
    end

    def token : Token
      @operator
    end

    def to_s(indent : Int = 0)
      "CompoundAssignment<\n" +
      "  #{TAB * indent}name: #{@name.to_s(indent + 1)},\n" +
      "  #{TAB * indent}operator: #{@operator.to_s},\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
