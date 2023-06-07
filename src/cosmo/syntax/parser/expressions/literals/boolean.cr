module Cosmo::AST::Expression
  class BooleanLiteral < Literal
    def initialize(@value : Bool, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end
end
