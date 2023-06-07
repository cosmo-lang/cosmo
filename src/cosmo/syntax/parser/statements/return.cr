module Cosmo::AST::Statement
  class Return < Base
    getter value : Expression::Base
    getter keyword : Token

    def initialize(@value, @keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_return_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Return<\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
