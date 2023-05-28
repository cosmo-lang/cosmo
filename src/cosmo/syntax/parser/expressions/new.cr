module Cosmo::AST::Expression
  class New < Base
    getter token : Token
    getter operand : Var | FunctionCall

    def initialize(@token, @operand)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_new_expr(self)
    end

    def to_s(indent : Int = 0)
      "New<operand: #{@operand.to_s(indent + 1)}>"
    end
  end
end
