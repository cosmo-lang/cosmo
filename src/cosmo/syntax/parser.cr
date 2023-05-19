require "./lexer"
require "./parser/ast"; include Cosmo::AST

class Cosmo::Parser
  @position : Int32 = 0
  @tokens : Array(Token)

  def initialize(source : String, file_path : String, @run_benchmarks : Bool)
    TypeChecker.reset if file_path == "test"
    lexer = Lexer.new(source, file_path, @run_benchmarks)
    @tokens = lexer.tokenize
    @tokens.pop
  end

  # Entry point
  def parse : Array(Statement::Base)
    start_time = Time.monotonic

    statements = [] of Statement::Base
    until finished?
      stmt = parse_statement
      statements << stmt
    end

    end_time = Time.monotonic
    puts "Parser took #{get_elapsed(start_time, end_time)}." if @run_benchmarks
    statements
  end

  # Parse a statement and return a node
  private def parse_statement : Statement::Base
    if at_fn_type?
      parse_fn_def_statement
    elsif match?(Syntax::Return)
      parse_return_statement
    elsif match?(Syntax::Break)
      Statement::Break.new(last_token)
    elsif match?(Syntax::Next)
      Statement::Next.new(last_token)
    elsif match?(Syntax::If)
      parse_if_statement
    elsif match?(Syntax::Unless)
      parse_unless_statement
    elsif match?(Syntax::While)
      parse_while_statement
    elsif match?(Syntax::Until)
      parse_until_statement
    elsif match?(Syntax::Every)
      parse_every_statement
    elsif check?(Syntax::LBrace)
      parse_block
    else
      Statement::SingleExpression.new(parse_expression)
    end
  end

  # Parse a block of statements and return a node
  private def parse_block : Statement::Block
    consume(Syntax::LBrace)
    statements = [] of Statement::Base

    until finished? || current.type == Syntax::RBrace
      statements << parse_statement
    end

    consume(Syntax::RBrace)
    Statement::Block.new(statements)
  end

  private def parse_every_statement : Statement::Every
    token = last_token
    type_info = parse_type
    typedef = type_info[:type_ref].not_nil!.name

    consume(Syntax::Identifier)
    ident = last_token
    var = Expression::Var.new(ident)
    var_declaration = Expression::VarDeclaration.new(typedef, var, Expression::NoneLiteral.new(nil, ident), type_info[:is_const])

    consume(Syntax::In)
    enumerable = parse_expression
    block = parse_statement
    Statement::Every.new(token, var_declaration, enumerable, block)
  end

  private def parse_while_statement : Statement::While
    token = last_token
    condition = parse_expression
    block = parse_statement
    Statement::While.new(token, condition, block)
  end

  private def parse_until_statement : Statement::Until
    token = last_token
    condition = parse_expression
    block = parse_statement
    Statement::Until.new(token, condition, block)
  end

  private def parse_if_statement : Statement::If
    token = last_token
    condition = parse_expression
    then_block = parse_statement
    if match?(Syntax::Else)
      if match?(Syntax::If)
        else_block = parse_if_statement
      else
        else_block = parse_statement
      end
    end
    Statement::If.new(token, condition, then_block, else_block)
  end

  private def parse_unless_statement : Statement::Unless
    token = last_token
    condition = parse_expression
    then_block = parse_statement
    if match?(Syntax::Else)
      if match?(Syntax::Unless)
        else_block = parse_unless_statement
      else
        else_block = parse_statement
      end
    end
    Statement::Unless.new(token, condition, then_block, else_block)
  end

  private def parse_return_statement : Statement::Return
    value = check?(Syntax::RBrace) ? nil : parse_expression
    Statement::Return.new(value || Expression::NoneLiteral.new(nil, last_token), last_token)
  end

  private def parse_fn_def_statement : Statement::FunctionDef
    type_info = parse_type(required: true)
    return_typedef = type_info[:type_ref].not_nil!.name
    consume(Syntax::Function)
    consume(Syntax::Identifier)
    function_ident = last_token
    consume(Syntax::LParen)
    params = parse_fn_params
    consume(Syntax::RParen)
    body = parse_block
    Statement::FunctionDef.new(function_ident, params, body, return_typedef)
  end

  # Parse function parameters and return an array of nodes
  private def parse_fn_params : Array(Expression::Parameter)
    params = [] of Expression::Parameter

    type_info = parse_type(required: false, check_const: true)
    if type_info[:found_typedef]
      param_type = type_info[:type_ref].not_nil!.name
      is_const = type_info[:is_const]
      consume(Syntax::Identifier)
      param_ident = last_token

      if match?(Syntax::Equal)
        value = parse_expression
        params << Expression::Parameter.new(param_type, param_ident, is_const, value)
      else
        params << Expression::Parameter.new(param_type, param_ident, is_const)
      end

      while match?(Syntax::Comma)
        type_info = parse_type(required: true, check_const: true)
        param_type = type_info[:type_ref].not_nil!.name
        is_const = type_info[:is_const]
        consume(Syntax::Identifier)
        param_ident = last_token
        if match?(Syntax::Equal)
          value = parse_expression
          params << Expression::Parameter.new(param_type, param_ident, is_const, value)
        else
          params << Expression::Parameter.new(param_type, param_ident, is_const)
        end
      end
    end

    params
  end

  # Parse an expression and return a node
  private def parse_expression : Expression::Base
    left = parse_after(parse_var_declaration)

    if match?(Syntax::Question)
      left = parse_ternary_op(left)
    end

    left
  end

  private def parse_ternary_op(condition : Expression::Base) : Expression::Base
    op = last_token
    then_expression = parse_expression
    consume(Syntax::Colon)
    else_expression = parse_expression
    Expression::TernaryOp.new(condition, op, then_expression, else_expression)
  end

  private ACCESS_SYNTAXES = [Syntax::ColonColon, Syntax::Dot, Syntax::HyphenArrow]
  private def parse_after(expr : Expression::Base) : Expression::Base
    callee = expr

    if match?(Syntax::LParen)
      arguments = [] of Expression::Base
      until match?(Syntax::RParen)
        arguments << parse_expression
        match?(Syntax::Comma)
      end
      callee = Expression::FunctionCall.new(callee, arguments)
    elsif match?(Syntax::LBracket)
      key = parse_expression
      consume(Syntax::RBracket)
      callee = Expression::Index.new(callee, key)
    elsif token_exists? && ACCESS_SYNTAXES.includes?(current.type) # it's a property access
      consume_current
      consume(Syntax::Identifier)
      key = last_token
      callee = Expression::Access.new(callee, key)
    end

    if token_exists? && (current.type == Syntax::LBracket || current.type == Syntax::LParen || ACCESS_SYNTAXES.includes?(current.type))
      callee = parse_after(callee)
    end

    callee
  end

  private alias TypeInfo = NamedTuple(
    found_typedef: Bool,
    variable_type: Token?,
    type_ref: Expression::TypeRef?,
    is_const: Bool,
    is_nullable: Bool
  )

  # i dont wanna talk about this method
  private def parse_type(required : Bool = true, check_const : Bool = false, paren_depth : Int = 0) : TypeInfo
    is_nullable = false
    is_const = match?(Syntax::Const) if check_const
    if check?(Syntax::LParen) &&
      token_exists?(1) && (peek.type == Syntax::TypeDef || peek.type == Syntax::Identifier) &&
      token_exists?(2) && (peek(2).type == Syntax::Identifier ||
      peek(2).type == Syntax::Pipe ||
      peek(2).type == Syntax::HyphenArrow ||
      peek(2).type == Syntax::LBracket ||
      peek(2).type == Syntax::RParen)

      consume(Syntax::LParen)
      info = parse_type(required: required, check_const: false, paren_depth: paren_depth + 1)
      consume(Syntax::RParen)

      variable_type, type_ref = parse_type_suffix(info[:variable_type].not_nil!, required, paren_depth)
      return {
        found_typedef: info[:found_typedef],
        variable_type: variable_type,
        type_ref: type_ref,
        is_const: info[:is_const],
        is_nullable: info[:is_nullable]
      }
    end

    if required
      consume(Syntax::Identifier) unless match?(Syntax::TypeDef)
      found_typedef = true
    else
      found_registered_type = !finished? &&
        current.type == Syntax::Identifier &&
        !TypeChecker.get_registered_type?(current.value.to_s, current).nil?

      found_typedef = match?(Syntax::TypeDef) || found_registered_type
    end

    variable_type = last_token if found_typedef
    if found_registered_type
      variable_type = current
      consume_current
    end
    unless variable_type.nil?
      variable_type, type_ref = parse_type_suffix(variable_type, required, paren_depth)
    end

    {
      found_typedef: found_typedef,
      variable_type: variable_type,
      type_ref: type_ref,
      is_const: is_const || false,
      is_nullable: is_nullable
    }
  end

  private def parse_type_suffix(variable_type : Token, required : Bool = true, paren_depth : Int = 0) : Tuple(Token, Expression::TypeRef)
    if match?(Syntax::LBracket)
      consume(Syntax::RBracket)
      vector_type = variable_type.lexeme + "[]"
      vector_type_token = Token.new(vector_type, variable_type.type, vector_type, variable_type.location)
      variable_type = vector_type_token
      type_ref = Expression::TypeRef.new(variable_type)
      while match?(Syntax::LBracket)
        consume(Syntax::RBracket)
        vector_type = variable_type.lexeme + "[]"
        vector_type_token = Token.new(vector_type, variable_type.type, vector_type, variable_type.location)
        variable_type = vector_type_token
        type_ref = Expression::TypeRef.new(variable_type)
      end
    else
      type_ref = Expression::TypeRef.new(variable_type)
    end
    if match?(Syntax::HyphenArrow)
      # type_ref is the key type, parse the value type
      type_info = parse_type(required: required, paren_depth: paren_depth)
      if type_info[:variable_type].nil?
        Logger.report_error("Expected table value type, got", current.type.to_s, current)
      end

      table_type = "#{variable_type.lexeme}->#{type_info[:variable_type].not_nil!.lexeme}"
      table_type_token = Token.new(table_type, variable_type.type, table_type, variable_type.location)
      variable_type = table_type_token
      type_ref = Expression::TypeRef.new(variable_type)
    end
    if match?(Syntax::Question)
      is_nullable = true
      nullable_type = variable_type.lexeme + "?"
      nullable_type_token = Token.new(nullable_type, variable_type.type, nullable_type, variable_type.location)
      variable_type = nullable_type_token
      type_ref = Expression::TypeRef.new(variable_type)
    end
    if match?(Syntax::Pipe)
      # type_ref is type a, parse type b
      type_info = parse_type(required: required, paren_depth: paren_depth)
      Logger.report_error(
        "Expected right operand to union type, got",
        token_exists? ? current.type.to_s : "EOF",
        token_exists? ? current : last_token
      ) if type_info[:variable_type].nil?

      union_type = "#{variable_type.lexeme}|#{type_info[:variable_type].not_nil!.lexeme}"
      union_type_token = Token.new(union_type, variable_type.type, union_type, variable_type.location)
      variable_type = union_type_token
      type_ref = Expression::TypeRef.new(variable_type)
    end

    {variable_type, type_ref}
  end

  private def at_fn_type?(offset : Int = 0) : Bool
    return false unless token_exists?(offset + 1)

    cur = peek(offset)
    last = token_exists?(offset - 1) ? peek(offset - 1) : nil
    peeked = peek(offset + 1)
    next_peeked = token_exists?(offset + 2) ? peek(offset + 2) : nil

    if (cur.type == Syntax::Const && !last.nil? && last.type != Syntax::Const) || cur.type == Syntax::LParen
      at_fn_type?(offset: offset + 1) ## skip the token
    else
      return at_fn_type?(offset: offset + 2) if peeked.type == Syntax::LBracket && !next_peeked.nil? && next_peeked.type == Syntax::RBracket
      return at_fn_type?(offset: offset + 1) if peeked.type == Syntax::HyphenArrow || peeked.type == Syntax::Question || peeked.type == Syntax::RParen
      if peeked.type == Syntax::Pipe && !next_peeked.nil? && (next_peeked.type == Syntax::TypeDef || next_peeked.type == Syntax::Identifier)
        return at_fn_type?(offset: offset + 2)
      end

      peeked.type == Syntax::Function
    end
  end

  private def parse_type_alias(type_token : Token, identifier : Expression::Var) : Expression::TypeAlias
    if match?(Syntax::Equal)
      type_info = parse_type(required: false)
      type_ref = type_info[:type_ref].not_nil!
      TypeChecker.alias_type(identifier.token.value.to_s, type_ref.name.value.to_s)
      Expression::TypeAlias.new(type_token, identifier, type_ref)
    else
      Expression::TypeAlias.new(type_token, identifier, nil)
    end
  end

  # Parse a variable declaration and return a node
  private def parse_var_declaration : Expression::Base
    type_info = parse_type(required: false, check_const: true)
    unless type_info[:variable_type].nil? || type_info[:type_ref].nil?
      typedef = type_info[:type_ref].nil? ? type_info[:variable_type].not_nil! : type_info[:type_ref].not_nil!.name

      if match?(Syntax::Identifier)
        variable_name = last_token
        identifier = Expression::Var.new(variable_name)
        if typedef.value == "type"
          parse_type_alias(typedef, identifier)
        else
          if match?(Syntax::Equal)
            value = parse_expression
            Expression::VarDeclaration.new(typedef, identifier, value, type_info[:is_const])
          else
            Expression::VarDeclaration.new(typedef, identifier, Expression::NoneLiteral.new(nil, variable_name), type_info[:is_const])
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
  private def parse_assignment : Expression::Base
    left = parse_compound_assignment

    while match?(Syntax::Equal)
      value = parse_assignment
      if left.is_a?(Expression::Var)
        left = Expression::VarAssignment.new(left, value)
      elsif left.is_a?(Expression::Index) || left.is_a?(Expression::Access)
        left = Expression::PropertyAssignment.new(left, value)
      else
        Logger.report_error("Expected identifier or property, got", peek(-2).type.to_s, peek(-2))
      end

    end

    left
  end

  private def parse_compound_assignment : Expression::Base
    left = parse_compound_assignment_factor

    while match?(Syntax::PlusEqual) || match?(Syntax::MinusEqual)
      op = last_token
      right = parse_compound_assignment_factor
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  private def parse_compound_assignment_factor : Expression::Base
    left = parse_compound_assignment_coeff

    while match?(Syntax::StarEqual) || match?(Syntax::SlashEqual) || match?(Syntax::PercentEqual)
      op = last_token
      right = parse_compound_assignment_coeff
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  private def parse_compound_assignment_coeff : Expression::Base
    left = parse_logical_or

    while match?(Syntax::CaratEqual)
      op = last_token
      right = parse_logical_or
      left = Expression::CompoundAssignment.new(peek(-3), op, right)
    end

    left
  end

  # Parse a logical OR expression and return a node
  private def parse_logical_or : Expression::Base
    left = parse_logical_and

    while match?(Syntax::Pipe)
      op = last_token
      right = parse_logical_and
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a logical AND expression and return a node
  private def parse_logical_and : Expression::Base
    left = parse_equality

    while match?(Syntax::Ampersand)
      op = last_token
      right = parse_equality
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an equality expression and return a node
  private def parse_equality : Expression::Base
    left = parse_comparison

    while match?(Syntax::EqualEqual) || match?(Syntax::BangEqual) || match?(Syntax::Is)
      op = last_token
      if op.lexeme == "is"
        type_info = parse_type
        left = Expression::Is.new(left, type_info[:type_ref].not_nil!)
      else
        right = parse_comparison
        left = Expression::BinaryOp.new(left, op, right)
      end
    end

    left
  end

  # Parse a comparison expression and return a node
  private def parse_comparison : Expression::Base
    left = parse_addition

    while match?(Syntax::Less) || match?(Syntax::LessEqual) || match?(Syntax::Greater) || match?(Syntax::GreaterEqual)
      op = last_token
      right = parse_addition
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an addition expression and return a node
  private def parse_addition : Expression::Base
    left = parse_multiplication

    while match?(Syntax::Plus) || match?(Syntax::Minus)
      op = last_token
      right = parse_multiplication
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a multiplication expression and return a node
  private def parse_multiplication : Expression::Base
    left = parse_exponentiation

    while match?(Syntax::Star) || match?(Syntax::Slash) || match?(Syntax::Percent)
      op = last_token
      right = parse_exponentiation
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an exponentiation expression and return a node
  private def parse_exponentiation : Expression::Base
    left = parse_unary

    while match?(Syntax::Carat) || match?(Syntax::DotDot)
      op = last_token
      right = parse_unary
      unless op.type == Syntax::DotDot
        left = Expression::BinaryOp.new(left, op, right)
      else
        left = Expression::RangeLiteral.new(left, right)
      end
    end

    left
  end

  # Parse a unary expression and return a node
  private def parse_unary : Expression::Base
    if match?(Syntax::Plus) || match?(Syntax::Minus) || match?(Syntax::PlusPlus) || match?(Syntax::MinusMinus) || match?(Syntax::Bang) || match?(Syntax::Star) || match?(Syntax::Hashtag)
      op = last_token
      operand = parse_unary
      Expression::UnaryOp.new(op, operand)
    else
      parse_primary
    end
  end

  # Parse a primary expression and return a node
  private def parse_primary : Expression::Base
    if match?(Syntax::LParen)
      node = parse_expression
      consume(Syntax::RParen)
      node
    elsif match?(Syntax::Identifier)
      ident = last_token
      callee = Expression::Var.new(ident)
      parse_after(callee)
    else
      parse_literal
    end
  end

  private def parse_table_key : Expression::Base
    if match?(Syntax::Identifier)
      Expression::StringLiteral.new(last_token.value.to_s, last_token)
    elsif match?(Syntax::String)
      Expression::StringLiteral.new(last_token.value.to_s, last_token)
    else
      Logger.report_error("Invalid table key", current.value.to_s, current)
    end
  end

  private def parse_table_literal : Expression::TableLiteral
    hash = {} of Expression::Base => Expression::Base

    until match?(Syntax::DoubleRBrace)
      if match?(Syntax::LBracket)
        key = parse_expression
        consume(Syntax::RBracket)
      else
        key = parse_table_key
      end
      consume(Syntax::HyphenArrow)
      value = parse_expression
      hash[key] = value
      match?(Syntax::Comma)
    end

    Expression::TableLiteral.new(hash, last_token)
  end

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
    when Syntax::DoubleLBrace
      consume_current
      parse_table_literal
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
      Logger.report_error("Invalid syntax", current.lexeme, current)
    end
  end

  private def check?(syntax : Syntax) : Bool
    return false if finished?
    current.type == syntax
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

  # Default offset is *ZERO* for this method.
  private def token_exists?(offset : Int = 0) : Bool
    return false if finished?
    return false if @position + offset < 0
    !@tokens[@position + offset]?.nil?
  end

  # Whether or not we're at the end of the token stream
  private def finished? : Bool
    @position >= @tokens.size
  end

  private def check?(syntax : Syntax) : Bool
    return false if finished?
    current.type == syntax
  end

  # Consumes the token if the syntax matches, returns whether or not it was consumed
  # Basically a safe way to consume and see if it was consumed
  private def match?(syntax : Syntax) : Bool
    if check?(syntax)
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
