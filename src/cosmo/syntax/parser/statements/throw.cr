module Cosmo::AST::Statement
  class Throw < Base
    getter err : Expression::Base
    getter keyword : Token

    def initialize(@err, @keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_throw_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Throw<\n" +
      "  #{TAB * indent}err: #{@err.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
