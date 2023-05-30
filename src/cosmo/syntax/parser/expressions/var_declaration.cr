module Cosmo::AST::Expression
  class VarDeclaration < Base
    getter typedef : Token
    getter var : Var
    property value : Base
    getter? constant : Bool
    getter visibility : Visibility

    def initialize(@typedef, @var, @value, @constant, @visibility)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_declaration_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s(indent : Int = 0)
      "VarDeclaration<\n" +
      "  #{TAB * indent}typedef: #{@typedef.value},\n" +
      "  #{TAB * indent}var: #{@var.token.lexeme},\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "  #{TAB * indent}constant?: #{@constant}\n" +
      "  #{TAB * indent}visibility: #{@visibility.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
