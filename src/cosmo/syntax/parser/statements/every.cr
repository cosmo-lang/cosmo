module Cosmo::AST::Statement
  class Every < Base
    getter keyword : Token
    getter var : Expression::VarDeclaration
    getter enumerable : Expression::Base
    getter block : Base

    def initialize(@keyword, @var, @enumerable, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_every_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Every<\n" +
      "  #{TAB * indent}var: #{@var.to_s(indent + 1)},\n" +
      "  #{TAB * indent}in: #{@enumerable.to_s(indent + 1)}\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
