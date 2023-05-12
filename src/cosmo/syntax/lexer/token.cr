require "../syntax_type"
require "./location"

struct Cosmo::Token
  getter type : Syntax
  getter value : LiteralType
  getter start_location : Location
  getter end_location : Location

  def initialize(@type, @value, @start_location, @end_location)
  end

  def to_s
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
      @value.to_s
    end
  end
end
