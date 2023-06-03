class Cosmo::TypeHoister
  @pos : UInt32 = 0

  def initialize(@tokens : Array(Token))
  end

  def hoist_types : Nil
    @tokens.each_with_index do |token, i|
      @pos = i.to_u
      check_token(token)
    end
  end

  private def check_token(token : Token) : Nil
    case token.type
    when Syntax::Class
      TypeChecker.register_type(peek.lexeme) if token_exists?(1)
    end
  end

  private def peek(offset : Int = 1) : Token
    @tokens[@pos + offset]
  end

  private def token_exists?(offset : Int = 0) : Bool
    !@tokens[@pos + offset]?.nil?
  end
end
