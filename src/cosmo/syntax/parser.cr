require "./lexer"
require "./parser/ast"; include Cosmo::AST

class Cosmo::Parser
  getter position : UInt32 = 0
  getter tokens : Array(Token)

  def initialize(source : String, file_path : String)
    lexer = Lexer.new(source, file_path)
    @tokens = lexer.tokenize
  end

  # Entry point
  def parse
    parse_expression
  end

  # Parse an expression and return a node
  # This is just a simplified example
  private def parse_expression : Node
    parse_term
  end

  # Parse a term (e.g., multiplication or division) and return a node
  private def parse_term : Node
    left = parse_factor

    case current.type
    when
    Syntax::Plus,
    Syntax::Minus,
    Syntax::Star,
    Syntax::Slash,
    Syntax::Carat,
    Syntax::Percent,
    Syntax::Ampersand,
    Syntax::Pipe,
    Syntax::Less,
    Syntax::LessEqual,
    Syntax::Greater,
    Syntax::GreaterEqual,
    Syntax::BangEqual
      left = parse_binary_op(left)
    end

    left
  end

  private def parse_binary_op(left : Node)
    op = current.type
    consume(op)

    right = parse_term
    Expression::BinaryOp.new(left, op, right)
  end

  # Parse a factor (e.g. number or parentheses) and return a node
  private def parse_factor : Node
    case current.type
    when Syntax::LParen
      consume(Syntax::LParen)
      node = parse_expression
      consume(Syntax::RParen)
      node
    when Syntax::Plus, Syntax::Minus, Syntax::Star, Syntax::Hashtag, Syntax::Bang
      op = current.type
      consume(op)
      operand = parse_factor
      Expression::UnaryOp.new(op, operand)
    else
      parse_literal
    end
  end

  # Parse a number and return an AST node
  private def parse_literal : Expression::Literal
    value = current.value
    case current.type
    when Syntax::Integer
      consume(current.type)
      Expression::IntLiteral.new(value.as(Int))
    when Syntax::Float
      consume(current.type)
      Expression::FloatLiteral.new(value.as(Float))
    when Syntax::Boolean
      consume(current.type)
      Expression::BooleanLiteral.new(value.as(Bool))
    when Syntax::String
      consume(current.type)
      Expression::StringLiteral.new(value.to_s)
    when Syntax::Char
      consume(current.type)
      Expression::CharLiteral.new(value.as(Char))
    when Syntax::None
      consume(current.type)
      Expression::NoneLiteral.new
    else
      raise "Unhandled syntax type: #{current.type}"
    end
  end

  # Return the current token at the current position
  private def current : Token
    @tokens[@position]
  end

  # Consumes the character if it exists, returns whether or not it was consumed
  private def match?(syntax : Syntax)
    if current.type == syntax
      consume(syntax)
      true
    else
      false
    end
  end

  # Consume the current token if it matches the expected syntax
  private def consume(syntax : Syntax)
    Logger.report_error("Expected #{syntax}, got", current.type.to_s, current.location.line, current.location.position) unless current.type == syntax
    @position += 1
  end

  # Consume the current token and advance the position
  def consume_current : String
    token = current
    @position += 1
    token
  end
end
