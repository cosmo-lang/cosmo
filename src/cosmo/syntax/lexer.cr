alias LiteralType = Int | Float | Bool | String | Char | Nil

class Lexer
  getter source : String

  def initialize(@source)
  end
end
