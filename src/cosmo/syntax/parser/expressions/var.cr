module Cosmo::AST::Expression
  class Var < Base
    getter token : Token

    def initialize(@token)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_expr(self)
    end

    def to_s(indent : Int = 0)
      "Var<\"#{@token.value.to_s}\">"
    end
  end
end
