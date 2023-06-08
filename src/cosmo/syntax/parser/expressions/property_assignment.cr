module Cosmo::AST::Expression
  class PropertyAssignment < Base
    getter object : Access | Index
    property value : Base | ValueType

    def initialize(@object, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_property_assignment_expr(self)
    end

    def token : Token
      @object.token
    end

    def to_s(indent : Int = 0)
      if value.is_a?(Base)
        value_s = @value.as(Base).to_s(indent + 1)
      else
        value_s = @value.to_s
      end
      "PropertyAssignment<object: #{@object.to_s(indent + 1)}, value: #{value_s}>"
    end
  end
end
