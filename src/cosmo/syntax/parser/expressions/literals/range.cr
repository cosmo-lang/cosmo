module Cosmo::AST::Expression
  class RangeLiteral < Base
    getter from : Base
    getter to : Base

    def initialize(@from, @to)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_range_literal_expr(self)
    end

    def token : Token
      @from.token
    end

    def to_s(indent : Int = 0)
      "RangeLiteral<\n" +
      "  #{TAB * indent}from: #{@from.to_s(indent + 1)},\n" +
      "  #{TAB * indent}to: #{@to.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
