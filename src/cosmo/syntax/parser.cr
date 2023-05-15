require "./lexer"
require "./parser/ast"; include Cosmo::AST

class Cosmo::Parser
  getter position : UInt32 = 0
  getter tokens : Array(Token)

  def initialize(source : String, file_path : String)
    TypeChecker.reset if file_path == "test"
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

    parse_regular_statement
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

  # Parse a block of statements and return a node
  private def parse_block : Statement::Block
    match?(Syntax::LBrace)
    statements = [] of Node

    until finished? || match?(Syntax::RBrace)
      statements << parse_statement
    end

    Statement::Block.new(statements)
  end

  # Parse a function definition and return a node
  private def parse_regular_statement : Node
    if current.type == Syntax::TypeDef && peek.type == Syntax::Function
      parse_function_def_statement
    elsif match?(Syntax::If)
      parse_if_statement
    elsif match?(Syntax::Unless)
      parse_unless_statement
    elsif match?(Syntax::While)
      parse_while_statement
    elsif match?(Syntax::Until)
      parse_until_statement
    else
      parse_expression
    end
  end

  private def parse_while_statement : Statement::While
    token = last_token
    condition = parse_expression
    block = parse_block
    Statement::While.new(token, condition, block)
  end

  private def parse_until_statement : Statement::Until
    token = last_token
    condition = parse_expression
    block = parse_block
    Statement::Until.new(token, condition, block)
  end

  private def parse_if_statement : Statement::If
    token = last_token
    condition = parse_expression
    then_block = parse_block
    if match?(Syntax::Else)
      if match?(Syntax::If)
        else_block = parse_if_statement
      else
        else_block = parse_block
      end
    end
    Statement::If.new(token, condition, then_block, else_block)
  end

  private def parse_unless_statement : Statement::Unless
    token = last_token
    condition = parse_expression
    then_block = parse_block
    if match?(Syntax::Else)
      if match?(Syntax::Unless)
        else_block = parse_unless_statement
      else
        else_block = parse_block
      end
    end
    Statement::Unless.new(token, condition, then_block, else_block)
  end

  private def parse_return_statement : Statement::Return
    value : Expression::Base? = check?(Syntax::RBrace) ? nil : parse_expression
    Statement::Return.new(value || Expression::NoneLiteral.new(nil, last_token), last_token)
  end

  private def parse_function_def_statement
    type_info = parse_type(required: true)
    return_typedef = type_info[:variable_type].not_nil!
    consume(Syntax::Function)
    consume(Syntax::Identifier)
    function_ident = last_token
    consume(Syntax::LParen)
    params = parse_function_params
    consume(Syntax::RParen)
    body = parse_block
    Statement::FunctionDef.new(function_ident, params, body, return_typedef)
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

  # Parse a function call and return a node
  private def parse_function_call(callee : Expression::Var) : Node
    arguments = [] of Node

    until match?(Syntax::RParen)
      arguments << parse_expression
      match?(Syntax::Comma)
    end

    Expression::FunctionCall.new(callee, arguments)
  end

  private def parse_type(as_value : Bool = false, required : Bool = true) : NamedTuple(found_typedef: Bool, variable_type: Token?, type_ref: Expression::TypeRef?)
    if required
      consume(Syntax::Identifier) unless match?(Syntax::TypeDef)
      found_typedef = true
    else
      found_typedef = match?(Syntax::TypeDef)
      found_custom_type = !finished? && current.type == Syntax::Identifier && !TypeChecker.get_registered_type?(current.value.to_s, current).nil?
    end

    if as_value
      variable_type = last_token
    else
      variable_type = last_token if found_typedef
      if found_custom_type
        variable_type = current
        consume_current
      end
    end

    type_ref = Expression::TypeRef.new(variable_type) unless variable_type.nil?
    {
      found_typedef: found_typedef,
      variable_type: variable_type,
      type_ref: type_ref
    }
  end

  private def parse_type_alias(type_token : Token, identifier : Expression::Var) : Expression::TypeAlias
    if match?(Syntax::Equal)
      type_info = parse_type(as_value: true)
      type_ref = type_info[:type_ref].not_nil!
      TypeChecker.alias_type(identifier.token.value.to_s, type_ref.name.value.to_s)
      Expression::TypeAlias.new(type_token, identifier, type_ref)
    else
      Expression::TypeAlias.new(type_token, identifier, nil)
    end
  end

  # Parse a variable declaration and return a node
  private def parse_var_declaration : Node
    type_info = parse_type(required: false)
    unless type_info[:variable_type].nil? && type_info[:type_ref].nil?
      typedef = type_info[:variable_type] || type_info[:type_ref].not_nil!.name

      if match?(Syntax::Identifier)
        variable_name = last_token
        identifier = Expression::Var.new(variable_name)
        if typedef.value == "type"
          parse_type_alias(typedef, identifier)
        else
          if match?(Syntax::Equal)
            value = parse_expression
            Expression::VarDeclaration.new(typedef, identifier, value)
          else
            Expression::VarDeclaration.new(typedef, identifier, Expression::NoneLiteral.new(nil, variable_name))
          end
        end
      else
        Logger.report_error("Expected identifier, got", current.type.to_s, current)
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

  # private def parse_table_key : Expression::Base
  #   if match?(Syntax::Identifier)
  #     Expression::StringLiteral.new(last_token.value.to_s, last_token)
  #   elsif match?(Syntax::String)
  #     Expression::StringLiteral.new(last_token.value.to_s, last_token)
  #   else
  #     Logger.report_error("Invalid table key", current.value.to_s, current)
  #   end
  # end

  # private def parse_table_literal
  #   hash = {} of Expression::Base => Expression::Base

  #   until match?(Syntax::RBrace)
  #     if match?(Syntax::LBracket)
  #       key = parse_expression
  #       consume(Syntax::RBracket)
  #     else
  #       key = parse_table_key
  #     end
  #     consume(Syntax::HyphenArrow)
  #     value = parse_expression
  #     hash[key] = value
  #     match?(Syntax::Comma)
  #   end

  #   Expression::TableLiteral.new(hash, last_token)
  # end

  private def parse_vector_literal : Expression::VectorLiteral
    elements = [] of Expression::Base

    until match?(Syntax::RBracket)
      elements << parse_expression
      match?(Syntax::Comma)
    end

    Expression::VectorLiteral.new(elements, last_token)
  end

  # Parse a number and return an AST node
  private def parse_literal : Expression::Literal | Expression::VectorLiteral
    value = current.value
    case current.type
    when Syntax::LBracket
      consume_current
      parse_vector_literal
    # when Syntax::LBrace
    #   consume_current
    #   parse_table_literal
    when Syntax::Integer
      consume_current
      Expression::IntLiteral.new(value.as(Int), last_token)
    when Syntax::Float
      consume_current
      Expression::FloatLiteral.new(value.as(Float), last_token)
    when Syntax::Boolean
      consume_current
      Expression::BooleanLiteral.new(value.as(Bool), last_token)
    when Syntax::String
      consume_current
      Expression::StringLiteral.new(value.to_s, last_token)
    when Syntax::Char
      consume_current
      Expression::CharLiteral.new(value.as(Char), last_token)
    when Syntax::None
      consume_current
      Expression::NoneLiteral.new(nil, last_token)
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
