module Cosmo::AST::Expression
  abstract class Literal < Base
    getter token : Token
    getter value : LiteralType

    def initialize(@value, @token); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_literal_expr(self)
    end
  end
end

require "./literals/char"
require "./literals/float"
require "./literals/int"
require "./literals/bigint"
require "./literals/boolean"
require "./literals/none"
require "./literals/string"
require "./literals/string_interpolation"
require "./literals/vector"
require "./literals/table"
require "./literals/range"
require "./literals/lambda"
