module Cosmo::AST::Expression
  class Cast < Base
    getter type : TypeRef
    getter value : Base

    def initialize(@type, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_cast_expr(self)
    end

    def token : Token
      @type.token
    end

    def to_s(indent : Int = 0)
      "Cast<\n" +
      "  #{TAB * indent}type: #{@type.to_s(indent + 1)},\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
