module Cosmo::AST::Expression
  class Lambda < Base
    getter parameters : Array(Parameter)
    getter body : Statement::Base
    getter return_typedef : Token

    def initialize(@parameters, @body, @return_typedef)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_lambda_expr(self)
    end

    def token : Token
      @return_typedef
    end

    def to_s(indent : Int = 0)
      "Lambda<\n" +
      "  #{TAB * indent}parameters: [\n" +
      "    #{TAB * indent}#{@parameters.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}return_typedef: #{@return_typedef.value},\n" +
      "  #{TAB * indent}body: #{@body.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
