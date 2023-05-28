module Cosmo::AST::Expression
  class BinaryOp < Base
    getter left : Base
    getter operator : Token
    getter right : Base

    def initialize(@left, @operator, @right)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_binary_op_expr(self)
    end

    def token : Token
      @left.token
    end

    def to_s(indent : Int = 0)
      "Binary<\n" +
      "  #{TAB * indent}left: #{@left.to_s(indent + 1)},\n" +
      "  #{TAB * indent}operator: #{@operator.to_s},\n" +
      "  #{TAB * indent}right: #{@right.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
