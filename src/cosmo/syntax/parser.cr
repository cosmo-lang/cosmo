require "./lexer"
require "./parser/ast"; include Cosmo::AST

class Cosmo::Parser
  getter position : UInt32 = 0
  getter tokens : Array(Token)

  def initialize(source : String, file_path : String)
    lexer = Lexer.new(source, file_path)
    @tokens = lexer.tokenize
    @tokens.pop
  end

  # Entry point
  def parse : Array(Statement::Base)
    statements = [] of Statement::Base
    until finished?
      statements << parse_statement
    end
    statements
  end

  # Parse an expression and return a node
  private def parse_expression : Expression::Base
    callee = parse_var_declaration

    if match?(Syntax::LParen)
      callee = parse_function_call(callee.as Expression::Var)
    end

    callee
  end

  private def parse_statement_expression
    if match?(Syntax::Return)
      return parse_return_statement
    end

    parse_function_definition
  end

  # Parse a statement and return a node
  private def parse_statement : Statement::Base
    stmt = parse_statement_expression
    if stmt.is_a?(Expression::Base)
      Statement::SingleExpression.new(stmt)
    else
      stmt.as Statement::Base
    end
  end

  private def parse_return_statement : Statement::Return
    value : Expression::Base? = check?(Syntax::RBrace) ? nil : parse_expression
    Statement::Return.new(value || Expression::NoneLiteral.new, last_token)
  end

  # Parse a block of statements and return a node
  private def parse_block : Statement::Block
    match?(Syntax::LBrace)
    statements = [] of Node

    until finished? || match?(Syntax::RBrace)
      statements << parse_statement
    end

    Statement::Block.new(statements)
  end

  # Parse a function call and return a node
  private def parse_function_call(callee : Expression::Var) : Node
    arguments = [] of Node

    until match?(Syntax::RParen)
      arguments << parse_expression
      match?(Syntax::Comma)
    end

    Expression::FunctionCall.new(callee, arguments)
  end

  # Parse a function definition and return a node
  private def parse_function_definition : Node
    if current.type == Syntax::TypeDef && peek.type == Syntax::Function
      consume(Syntax::TypeDef)
      return_typedef = last_token
      consume(Syntax::Function)
      consume(Syntax::Identifier)
      function_ident = last_token
      consume(Syntax::LParen)
      params = parse_function_params
      consume(Syntax::RParen)
      body = parse_block
      Statement::FunctionDef.new(function_ident, params, body, return_typedef)
    else
      parse_expression
    end
  end

  # Parse function parameters and return an array of nodes
  private def parse_function_params : Array(Expression::Parameter)
    params = [] of Expression::Parameter

    if match?(Syntax::TypeDef)
      param_type = last_token
      consume(Syntax::Identifier)
      param_ident = last_token

      if match?(Syntax::Equal)
        value = parse_expression
        params << Expression::Parameter.new(param_type, param_ident, value)
      else
        params << Expression::Parameter.new(param_type, param_ident)
      end

      while match?(Syntax::Comma)
        consume(Syntax::TypeDef)
        param_type = last_token
        consume(Syntax::Identifier)
        param_ident = last_token
        if match?(Syntax::Equal)
          value = parse_expression
          params << Expression::Parameter.new(param_type, param_ident, value)
        else
          params << Expression::Parameter.new(param_type, param_ident)
        end
      end
    end

    params
  end

  # Parse a variable declaration and return a node
  private def parse_var_declaration : Node
    if match?(Syntax::TypeDef)
      variable_type = last_token

      if match?(Syntax::Identifier)
        variable_name = last_token
        identifier = Expression::Var.new(variable_name)
        if match?(Syntax::Equal)
          value = parse_expression
          Expression::VarDeclaration.new(variable_type, identifier, value)
        else
          Expression::VarDeclaration.new(variable_type, identifier, Expression::NoneLiteral.new)
        end
      else
        Logger.report_error("Expected identifier, got", last_token.type.to_s, last_token)
      end
    else
      parse_assignment
    end
  end

  # Parse a variable assignment expression and return a node
  private def parse_assignment : Node
    left = parse_compound_assignment

    while match?(Syntax::Equal)
      unless left.is_a?(Expression::Var)
        Logger.report_error("Expected identifier, got", peek(-2).type.to_s, peek(-2))
      end
      value = parse_assignment
      left = Expression::VarAssignment.new(left, value)
    end

    left
  end

  private def parse_compound_assignment
    left = parse_compound_assignment_factor

    while match?(Syntax::PlusEqual) || match?(Syntax::MinusEqual)
      op = last_token
      right = parse_compound_assignment_factor
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  private def parse_compound_assignment_factor
    left = parse_compound_assignment_coeff

    while match?(Syntax::StarEqual) || match?(Syntax::SlashEqual) || match?(Syntax::PercentEqual)
      op = last_token
      right = parse_compound_assignment_coeff
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  private def parse_compound_assignment_coeff
    left = parse_logical_or

    while match?(Syntax::CaratEqual)
      op = last_token
      right = parse_logical_or
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  # Parse a logical OR expression and return a node
  private def parse_logical_or : Node
    left = parse_logical_and

    while match?(Syntax::Pipe)
      op = last_token
      right = parse_logical_and
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a logical AND expression and return a node
  private def parse_logical_and : Node
    left = parse_equality

    while match?(Syntax::Ampersand)
      op = last_token
      right = parse_equality
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an equality expression and return a node
  private def parse_equality : Node
    left = parse_comparison

    while match?(Syntax::EqualEqual) || match?(Syntax::BangEqual)
      op = last_token
      right = parse_comparison
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a comparison expression and return a node
  private def parse_comparison : Node
    left = parse_addition

    while match?(Syntax::Less) || match?(Syntax::LessEqual) || match?(Syntax::Greater) || match?(Syntax::GreaterEqual)
      op = last_token
      right = parse_addition
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an addition expression and return a node
  private def parse_addition : Node
    left = parse_multiplication

    while match?(Syntax::Plus) || match?(Syntax::Minus)
      op = last_token
      right = parse_multiplication
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a multiplication expression and return a node
  private def parse_multiplication : Node
    left = parse_exponentiation

    while match?(Syntax::Star) || match?(Syntax::Slash) || match?(Syntax::Percent)
      op = last_token
      right = parse_exponentiation
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an exponentiation expression and return a node
  private def parse_exponentiation : Node
    left = parse_unary

    while match?(Syntax::Carat)
      op = last_token
      right = parse_unary
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a unary expression and return a node
  private def parse_unary : Node
    if match?(Syntax::Plus) || match?(Syntax::Minus) || match?(Syntax::Bang) || match?(Syntax::Star)
      op = last_token
      operand = parse_unary
      Expression::UnaryOp.new(op, operand)
    else
      parse_primary
    end
  end

  # Parse a factor (e.g. number or parentheses) and return a node
  private def parse_factor : Node
    case current.type
    when Syntax::LParen
      consume_current
      node = parse_expression
      consume(Syntax::RParen)
      node
    else
      parse_literal
    end
  end

  # Parse a number and return an AST node
  private def parse_literal : Expression::Literal
    value = current.value
    case current.type
    when Syntax::Integer
      consume_current
      Expression::IntLiteral.new(value.as(Int))
    when Syntax::Float
      consume_current
      Expression::FloatLiteral.new(value.as(Float))
    when Syntax::Boolean
      consume_current
      Expression::BooleanLiteral.new(value.as(Bool))
    when Syntax::String
      consume_current
      Expression::StringLiteral.new(value.to_s)
    when Syntax::Char
      consume_current
      Expression::CharLiteral.new(value.as(Char))
    when Syntax::None
      consume_current
      Expression::NoneLiteral.new
    else
      raise "Unhandled syntax type: #{current.type}"
    end
  end

  # Parse a primary expression and return a node
  private def parse_primary : Node
    if match?(Syntax::LParen)
      node = parse_expression
      consume(Syntax::RParen)
      node
    elsif match?(Syntax::Identifier)
      ident = last_token
      if match?(Syntax::LParen) # it's a function call
        callee = Expression::Var.new(ident)
        parse_function_call(callee)
      else # it's a regular var ref
        Expression::Var.new(ident)
      end
    else
      parse_literal
    end
  end

  private def check?(syntax : Syntax) : Bool
    return false if finished?
    peek.type == syntax
  end

  # Return the current token at the current position
  private def current : Token
    peek 0
  end

  # Peeks ahead in the token stream by `offset`
  private def peek(offset : Int32 = 1) : Token
    @tokens[@position + offset]
  end

  # Return the token at the current position minus one
  private def last_token : Token
    peek -1
  end

  private def finished? : Bool
    @position >= @tokens.size
  end

  # Consumes the token if the syntax matches, returns whether or not it was consumed
  # Basically a safe way to consume and see if it was consumed
  private def match?(syntax : Syntax) : Bool
    return false if finished?
    if current.type == syntax
      consume(syntax)
      true
    else
      false
    end
  end

  # Consume the current token and advance position if token syntax
  # matches the expected syntax, else log an error
  private def consume(syntax : Syntax) : Nil
    Logger.report_error("Expected #{syntax}, got", current.type.to_s, current.location.line, current.location.position + 1) unless current.type == syntax
    @position += 1
  end

  # Consume the current token and advance the position
  private def consume_current : Token
    token = current
    @position += 1
    token
  end
end
