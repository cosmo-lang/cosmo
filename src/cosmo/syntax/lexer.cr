alias LiteralType = Int | Float | Bool | String | Char | Nil

class Cosmo::Lexer
  getter source : String

  def initialize(@source)
  end
end
