module Cosmo::AST::Expression
  class UnaryOp < Base
    getter operator : Token
    getter operand : Base

    def initialize(@operator, @operand)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_unary_op_expr(self)
    end

    def token : Token
      @operator
    end

    def to_s(indent : Int = 0)
      "Unary<\n" +
      "  #{TAB * indent}operator: #{@operator.to_s},\n" +
      "  #{TAB * indent}operand: #{@operand.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
