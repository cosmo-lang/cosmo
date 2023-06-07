module Cosmo::AST::Expression
  class IntLiteral < Literal
    def initialize(@value : Int64 | Int32 | Int16 | Int8, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end
end
