module Cosmo::AST::Expression
  class StringLiteral < Literal
    def initialize(@value : String, @token); end
    def to_s(indent : Int = 0)
      "Literal<\"#{@value}\">"
    end
  end
end
