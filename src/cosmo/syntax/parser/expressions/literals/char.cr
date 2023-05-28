module Cosmo::AST::Expression
  class CharLiteral < Literal
    def initialize(@value : Char, @token); end
    def to_s(indent : Int = 0)
      "Literal<'#{@value}'>"
    end
  end
end
