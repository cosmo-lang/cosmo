module Cosmo::AST::Expression
  class This < Base
    getter token : Token
    getter class_name : String

    def initialize(@token, @class_name)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_this_expr(self)
    end

    def to_s(indent : Int = 0)
      "This"
    end
  end
end
