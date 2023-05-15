require "./lexer/token"
require "./lexer/keywords"

alias LiteralType =
  Int64 | Int32 | Int16 | Int8 |
  Float64 | Float32 |
  Bool | String | Char | Nil

class Cosmo::Lexer
  @tokens : Array(Token)
  @line : UInt32 = 1
  @position : UInt32 = 0
  @char_pos : UInt32 = 0
  @tokens = [] of Token
  @current_lexeme : String = ""

  def initialize(@source : String, @file_path : String)
  end

  def tokenize : Array(Token)
    until finished?
      lex
    end

    add_token(Syntax::EOF, nil)
    @tokens
  end

  private def lex
    char = current_char
    @current_lexeme += char

    case char
    when "."
      if char_exists?(1) && peek.match(/[0-9]/)
        read_number
      else
        if match_char?(".")
          add_token(Syntax::DotDot, nil)
        else
          add_token(Syntax::Dot, nil)
        end
      end
    when "{"
      add_token(Syntax::LBrace, nil)
    when "}"
      add_token(Syntax::RBrace, nil)
    when "["
      add_token(Syntax::LBracket, nil)
    when "]"
      add_token(Syntax::RBracket, nil)
    when "("
      add_token(Syntax::LParen, nil)
    when ")"
      add_token(Syntax::RParen, nil)
    when "$"
      add_token(Syntax::This, nil)
    when ","
      add_token(Syntax::Comma, nil)
    when ";"
      advance
    when "\n"
      @line += 1
      @char_pos = 0
    when "\""
      read_string(char)
    when "'"
      read_char(char)
    when "#"
      if match_char?("#")
        skip_comments(multiline: false)
      elsif match_char?(":")
        skip_comments(multiline: true)
      else
        add_token(Syntax::Hashtag, nil)
      end
    when ":"
      if match_char?(":")
        add_token(Syntax::ColonColon, nil)
      else
        add_token(Syntax::Colon, nil)
      end
    when "+"
      if match_char?("=")
        add_token(Syntax::PlusEqual, nil)
      else
        add_token(Syntax::Plus, nil)
      end
    when "-"
      if match_char?("=")
        add_token(Syntax::MinusEqual, nil)
      elsif match_char?(">")
        add_token(Syntax::HyphenArrow, nil)
      else
        add_token(Syntax::Minus, nil)
      end
    when "*"
      if match_char?("=")
        add_token(Syntax::StarEqual, nil)
      else
        add_token(Syntax::Star, nil)
      end
    when "/"
      if match_char?("=")
        add_token(Syntax::SlashEqual, nil)
      else
        add_token(Syntax::Slash, nil)
      end
    when "^"
      if match_char?("=")
        add_token(Syntax::CaratEqual, nil)
      else
        add_token(Syntax::Carat, nil)
      end
    when "%"
      if match_char?("=")
        add_token(Syntax::PercentEqual, nil)
      else
        add_token(Syntax::Percent, nil)
      end
    when "&"
      add_token(Syntax::Ampersand, nil)
    when "|"
      add_token(Syntax::Pipe, nil)
    when "?"
      add_token(Syntax::Question, nil)
    when "!"
      if match_char?("=")
        add_token(Syntax::BangEqual, nil)
      else
        add_token(Syntax::Bang, nil)
      end
    when "="
      if match_char?("=")
        add_token(Syntax::EqualEqual, nil)
      else
        add_token(Syntax::Equal, nil)
      end
    when "<"
      if match_char?("=")
        add_token(Syntax::LessEqual, nil)
      else
        add_token(Syntax::Less, nil)
      end
    when ">"
      if match_char?("=")
        add_token(Syntax::GreaterEqual, nil)
      else
        add_token(Syntax::Greater, nil)
      end
    else
      default_char = @source[@position].to_s
      return skip_whitespace if default_char.blank?

      is_ident = default_char.match(/[a-zA-Z_$]/)
      is_number = default_char.match(/\d/) ||
        (default_char == "0" && peek == "x" && peek(2).match(/[0-9a-fA-F]/)) ||
        (default_char == "0" && peek == "b" && peek(2).match(/[01]/))

      if is_number
        read_number
      elsif is_ident
        read_identifier
      else
        Logger.report_error("Unexpected character", default_char.to_s, @position, @line)
      end
    end
    @position += 1
  end

  # Peek `offset` characters ahead of our current position
  # Returns a string because it's easier
  private def peek(offset : UInt32 = 1) : String
    @source[@position + offset].to_s
  end

  private def current_char : String
    peek 0
  end

  private def match_char?(expected)
    return false if finished?
    return false unless char_exists?(1)
    return false unless peek == expected
    advance
    true
  end

  private def finished?
    @position >= @source.size
  end

  private def char_exists?(offset)
    (@position + offset) < @source.size
  end

  private def advance : String
    char = @source[@position].to_s
    @position += 1
    @char_pos += 1
    char
  end

  private def add_token(syntax : Syntax, value : LiteralType)
    location = Location.new(@file_path, @line, @char_pos + 1)
    @tokens << Token.new(@current_lexeme, syntax, value, location)
    @current_lexeme = ""
  end

  private def is_base?(char : String, radix : Int) : Bool
    current_char == "0" &&
      char_exists?(1) &&
      peek == char &&
      char_exists?(2) &&
      !peek(2).to_i(radix).nil?
  end

  private def skip_comments(multiline : Bool)
    @current_lexeme = ""
    advance
    until end_of_comment(multiline, @line)
      advance
    end
  end

  private def end_of_comment(multiline : Bool, current_line : UInt32)
    multiline ?
      match_char?(":") && match_char?("#")
      : match_char?("\n") || finished?
  end

  private def skip_whitespace
    @current_lexeme = ""
    until finished? || !current_char.blank?
      advance
    end
  end

  private def read_number
    num_str = ""
    radix = 10
    if is_base?("x", 16)
      advance
      advance
      radix = 16
    elsif is_base?("b", 2)
      advance
      advance
      radix = 2
    elsif is_base?("o", 8)
      advance
      advance
      radix = 8
    end

    decimal_used = false
    until finished?
      char = current_char.downcase
      is_valid = char.to_i64?(radix).nil? ? false : char.to_i64(radix).to_s(radix) == char
      break unless is_valid || char == "."
      decimal_used = true if char == "."
      num_str += advance.to_s
    end

    @current_lexeme = num_str
    if decimal_used
      Logger.report_error("Unexpected float", "Hex/octal/binary literals must be integers", @line, @position) unless radix == 10
      add_token(Syntax::Float, num_str.to_f64)
    else
      add_token(Syntax::Integer, num_str.to_i64(radix))
    end

    @position -= 1
  end

  private def read_string(delim : String)
    advance
    res_str = ""
    until finished? || current_char == delim
      res_str += advance.to_s
    end

    @current_lexeme = res_str
    add_token(Syntax::String, res_str)
  end

  private def read_char(delim : String)
    advance
    res_str = ""
    until finished? || current_char == delim
      res_str += advance.to_s
      if res_str.size > 1
        Logger.report_error("Character overflow", "Character literal has more than one character", @position, @line)
        break
      end
    end

    @current_lexeme = res_str
    add_token(Syntax::Char, res_str.chars.first)
  end

  private def read_identifier
    ident_str = ""
    until finished?
      if char_exists?(1) && !peek.match(/[a-zA-Z0-9_$]/)
        ident_str += current_char.to_s
        skip_whitespace
        break
      end
      ident_str += advance
    end
    ident_str = ident_str.strip

    @current_lexeme = ident_str
    if Keywords.keyword?(ident_str)
      syntax_type = Keywords.get_syntax(ident_str)
      value = true if ident_str == "true"
      value = false if ident_str == "false"
      value = nil if ident_str == "none"
      add_token(syntax_type, value)
    elsif Keywords.type?(ident_str)
      add_token(Syntax::TypeDef, ident_str)
    else
      add_token(Syntax::Identifier, ident_str)
    end
  end
end
