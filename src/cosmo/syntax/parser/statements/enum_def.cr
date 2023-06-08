module Cosmo::AST::Statement
  class EnumDef < Base
    getter identifier : Token
    getter members : Array(Tuple(Token, Expression::Base?))
    getter visibility : Visibility

    def initialize(@identifier, @members, @visibility)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_enum_def_stmt(self)
    end

    def token : Token
      @identifier
    end

    def to_s(indent : Int = 0)
      "EnumDef<\n" +
      "  #{TAB * indent}identifier: #{@identifier.value.to_s},\n" +
      "  #{TAB * indent}visibility: #{@visibility.to_s}\n" +
      "  #{TAB * indent}members: [\n" +
      "    #{TAB * indent}#{@members.map(&.to_s).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}]\n" +
      "#{TAB * indent}>"
    end
  end
end
