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

  class Location
    getter line : UInt32
    getter position : UInt32
    getter file_name : String

    def initialize(@file_name, @line, @position)
    end

    def between?(min : UInt32, max : UInt32)
      return false unless min && max
      min <= self && self <= max
    end

    def directory
      @file_name.try { |file_name| File.dirname(file_name) }
    end

    def to_s
      "#{@file_name}:#{@line}:#{position}"
    end
  end
end
