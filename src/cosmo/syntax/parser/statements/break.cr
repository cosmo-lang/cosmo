module Cosmo::AST::Statement
  class Break < Base
    getter keyword : Token

    def initialize(@keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_break_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Break"
    end
  end
end
