module Cosmo::AST::Expression
  class TernaryOp < Base
    getter condition : Base
    getter operator : Token
    getter then : Base
    getter else : Base

    def initialize(@condition, @operator, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_ternary_op_expr(self)
    end

    def token : Token
      @operator
    end

    def to_s(indent : Int = 0)
      "Ternary<\n" +
      "  #{TAB * indent}left: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}then: #{@then.to_s(indent + 1)}\n" +
      "  #{TAB * indent}else: #{@else.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
