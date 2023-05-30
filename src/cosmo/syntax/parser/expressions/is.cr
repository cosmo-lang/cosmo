module Cosmo::AST::Expression
  class Is < Base
    getter value : Base
    getter type : TypeRef

    def initialize(@value, @type)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_is_expr(self)
    end

    def token : Token
      @value.token
    end

    def to_s(indent : Int = 0)
      "Is<\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)},\n" +
      "  #{TAB * indent}type: #{@type.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end