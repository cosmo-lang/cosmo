require "./lexer/token"

alias LiteralType =
  Int64 | Int32 | Int16 | Int8 |
  Float64 | Float32 |
  Bool | String | Char | Nil

class Cosmo::Lexer
  getter source : String

  def initialize(@source)
  end
end
