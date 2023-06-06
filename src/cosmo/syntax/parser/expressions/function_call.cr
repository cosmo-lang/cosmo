module Cosmo::AST::Expression
  class FunctionCall < Base
    getter callee : Base
    getter arguments : Array(Base)

    def initialize(@callee, @arguments)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_call_expr(self)
    end

    def token : Token
      @callee.token
    end

    def to_s(indent : Int = 0)
      "FunctionCall<\n" +
      "  #{TAB * indent}callee: #{@callee.to_s(indent + 1)},\n" +
      "  #{TAB * indent}arguments: [\n" +
      "    #{TAB * indent}#{@arguments.map(&.to_s(indent + 2)).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}]\n" +
      "#{TAB * indent}>"
    end
  end
end
