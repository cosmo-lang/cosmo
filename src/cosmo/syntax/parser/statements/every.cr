module Cosmo::AST::Statement
  class Every < Base
    getter keyword : Token
    getter vars : Array(Expression::VarDeclaration)
    getter enumerable : Expression::Base
    getter block : Base

    def initialize(@keyword, @vars, @enumerable, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_every_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Every<\n" +
      "  #{TAB * indent}vars: [\n" +
      "    #{TAB * indent}#{@vars.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}in: #{@enumerable.to_s(indent + 1)}\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
