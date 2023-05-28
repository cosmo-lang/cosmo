module Cosmo::AST::Statement
  class FunctionDef < Base
    getter identifier : Token
    getter parameters : Array(Expression::Parameter)
    getter body : Block
    getter return_typedef : Token
    getter visibility : Visibility

    def initialize(
      @identifier,
      @parameters,
      @body,
      @return_typedef,
      @visibility
    )
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_def_stmt(self)
    end

    def token : Token
      @identifier
    end

    def to_s(indent : Int = 0)
      "FunctionDef<\n" +
      "  #{TAB * indent}identifier: #{@identifier.value.to_s},\n" +
      "  #{TAB * indent}parameters: [\n" +
      "    #{TAB * indent}#{@parameters.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}return_typedef: #{@return_typedef.value},\n" +
      "  #{TAB * indent}body: #{@body.to_s(indent + 1)}\n" +
      "  #{TAB * indent}visibility: #{@visibility.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
