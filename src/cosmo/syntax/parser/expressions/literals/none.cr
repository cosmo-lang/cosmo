module Cosmo::AST::Expression
  class NoneLiteral < Literal
    def initialize(@value : Nil, @token); end
    def to_s(indent : Int = 0)
      "Literal<none>"
    end
  end
end
