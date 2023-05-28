module Cosmo::AST::Expression
  class TypeRef < Base
    getter name : Token

    def initialize(@name)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_type_ref_expr(self)
    end

    def token : Token
      @name
    end

    def to_s(indent : Int = 0)
      "TypeRef<\"#{@name.value.to_s}\">"
    end
  end
end
