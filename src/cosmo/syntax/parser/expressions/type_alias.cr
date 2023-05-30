module Cosmo::AST::Expression
  class TypeAlias < Base
    getter type_token : Token
    getter var : Var
    getter value : Expression::Base
    getter? mutable : Bool
    getter visibility : Visibility

    def initialize(@type_token, @var, @value, @mutable, @visibility)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_type_alias_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s(indent : Int = 0)
      "TypeAlias<\n" +
      "  #{TAB * indent}#{@var.token.value.to_s}: #{@value.nil? ? "none" : @value.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
