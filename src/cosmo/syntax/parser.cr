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
    parse_factor
  end

  # Parse a factor (e.g. number or parentheses) and return a node
  private def parse_factor : Node
    case current.type
    when Syntax::LParen
      consume(Syntax::LParen)
      node = parse_expression
      consume(Syntax::RParen)
      node
    when Syntax::Minus, Syntax::Bang
      op = current
      consume(current.type)
      operand = parse_factor
      Expression::UnaryOp.new(op.type, operand)
    else
      parse_literal
    end
  end

  # Parse a number and return an AST node
  private def parse_literal : Expression::Literal
    value = current.value
    case current.type
    when Syntax::Integer
      Expression::IntLiteral.new(value.as(Int))
    when Syntax::Float
      Expression::FloatLiteral.new(value.as(Float))
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
    Logger.report_error("Expected #{syntax.to_s}, got", current.type.to_s, current.location.line, current.location.position) unless current.type == syntax
    @position += 1
  end

  # Consume the current token and advance the position
  def consume_current : String
    token = current
    @position += 1
    token
  end
end
