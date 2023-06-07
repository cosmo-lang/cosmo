module Cosmo::AST::Statement
  class SingleExpression < Base
    getter expression : Expression::Base

    def initialize(@expression)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_single_expr_stmt(self)
    end

    def token : Token
      @expression.token
    end

    def to_s(indent : Int = 0)
      "SingleExpression<\n" +
      "  #{TAB * indent}expression: #{@expression.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
