require "../syntax_type"
require "./location"

struct Cosmo::Token
  property type : Syntax
  getter value : LiteralType
  getter location : Location
  property lexeme : String

  def initialize(@lexeme, @type, @value, @location)
  end

  private def value_str
    case @type
    when Syntax::Integer, Syntax::Float, Syntax::Boolean
      @value.to_s
    when Syntax::String
      "\"#{@value}\""
    when Syntax::Char
      "'#{@value}'"
    when Syntax::None
      "none"
    when Syntax::Identifier
      "Ident<#{@value}>"
    else
      @value.to_s == "" ? "none" : @value.to_s
    end
  end

  def to_s
    "Token<type: #{@type}, lexeme: \"#{@lexeme}\", value: #{value_str}>"
  end
end
