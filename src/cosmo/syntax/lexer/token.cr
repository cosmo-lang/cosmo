require "../syntax_type"
require "./location"

struct Cosmo::Token
  getter type : Syntax
  getter value : LiteralType
  getter location : Location
  getter lexeme : String

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
      "Ident<#{@value.to_s}>"
    else
      @value.to_s == "" ? "none" : @value.to_s
    end
  end

  def to_s
    "Token<type: #{@type}, value: #{value_str}, location: [#{@location.to_s}]"
  end
end
