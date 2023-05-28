module Cosmo::AST::Statement
  class Until < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter block : Base

    def initialize(@keyword, @condition, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_until_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Until<\n" +
      "  #{TAB * indent}condition: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
