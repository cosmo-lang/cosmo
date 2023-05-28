module Cosmo::AST::Expression
  class FloatLiteral < Literal
    def initialize(@value : Float64 | Float32 | Float16 | Float8, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end
end
