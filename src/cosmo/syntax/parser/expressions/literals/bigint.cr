module Cosmo::AST::Expression
  class BigIntLiteral < Literal
    def initialize(@value : Int128, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end
end
