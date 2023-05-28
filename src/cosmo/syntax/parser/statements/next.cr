module Cosmo::AST::Statement
  class Next < Base
    getter keyword : Token

    def initialize(@keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_next_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Next"
    end
  end
end
