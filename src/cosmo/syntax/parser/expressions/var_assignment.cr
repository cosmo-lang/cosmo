module Cosmo::AST::Expression
  class VarAssignment < Base
    getter var : Var
    property value : Base | ValueType

    def initialize(@var, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_assignment_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s(indent : Int = 0)
      if value.is_a?(Base)
        value_s = @value.as(Base).to_s(indent + 1)
      else
        value_s = @value.to_s
      end
      "VarAssignment<\n" +
      "  #{TAB * indent}var: #{@var.token.value.to_s},\n" +
      "  #{TAB * indent}value: #{value_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
