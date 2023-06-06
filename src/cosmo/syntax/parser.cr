require "./lexer"
require "./type_hoister"
require "./parser/ast"; include Cosmo::AST

class Cosmo::Parser
  @position : Int32 = 0
  @tokens : Array(Token)
  @not_assignment = false

  def initialize(
    source : String,
    @file_path : String,
    @run_benchmarks : Bool,
    @within_class : String? = nil
  )

    TypeChecker.reset if @file_path == "test"
    lexer = Lexer.new(source, @file_path, @run_benchmarks)
    @tokens = lexer.tokenize
    @tokens.pop
  end

  # Entry point
  def parse : Array(Statement::Base)
    start_time = Time.monotonic

    hoister = TypeHoister.new(@tokens)
    hoister.hoist_types

    last_statement : Statement::Base? = nil
    statements = [] of Statement::Base
    until finished?
      statement = parse_statement
      if statement.is_a?(Statement::SingleExpression) && statement.expression === LiteralExpression &&
        last_statement.is_a?(Statement::SingleExpression) && last_statement.expression === LiteralExpression

        Logger.report_error(
          "Invalid expression",
          "Two literal expressions may not be adjacent to each other. Got '#{last_statement.token.lexeme}' and '#{statement.token.lexeme}'",
          statement.token
        )
      end

      statements << statement
      last_statement = statement
    end

    end_time = Time.monotonic
    puts "Parser @#{@file_path} took #{get_elapsed(start_time, end_time)}." if @run_benchmarks
    statements
  end

  # Parse a statement and return a node
  private def parse_statement : Statement::Base
    case self
    when .at_fn_type?
      parse_fn_def_statement
    when .check?(Syntax::Class), .check?(Syntax::Class, 1)
      parse_class_def_statement
    # when .check?(Syntax::Enum), .check?(Syntax::Enum, 1)
    #   parse_enum_def_statement
    when .match?(Syntax::Use)
      parse_use_statement
    when .match?(Syntax::Throw)
      parse_throw_statement
    when .match?(Syntax::Return)
      parse_return_statement
    when .match?(Syntax::Break)
      Statement::Break.new(last_token)
    when .match?(Syntax::Next)
      Statement::Next.new(last_token)
    when .match?(Syntax::Case)
      parse_case_statement
    when .match?(Syntax::Try)
      parse_try_catch_statement
    when .match?(Syntax::If)
      parse_if_statement
    when .match?(Syntax::Unless)
      parse_unless_statement
    when .match?(Syntax::While)
      parse_while_statement
    when .match?(Syntax::Until)
      parse_until_statement
    when .match?(Syntax::Every)
      parse_every_statement
    when .check?(Syntax::LBrace)
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

  # private def parse_enum_def_statement : Statement::EnumDef
  #   has_visibility = match?(Syntax::Public)
  #   visibility = get_visibility(last_token.lexeme)

  #   consume(Syntax::Enum)
  #   token = last_token
  #   unless @within_class.nil?
  #     Logger.report_error("Invalid enum", "Enums may not be class members", token)
  #   end

  #   consume(Syntax::LBrace)

  #   members = [] of Tuple(Token, Expression::Base?)
  #   while match?(Syntax::Identifier)
  #     member_ident = last_token
  #     value = nil
  #     if match?(Syntax::Equal)
  #       value = parse_literal
  #     end
  #     members << {member_ident, value}
  #   end

  #   consume(Syntax::RBrace)
  #   Statement::EnumDef.new(identifier, members, visibility)
  # end

  private def parse_class_def_statement : Statement::ClassDef
    has_visibility = match?(Syntax::Public)
    visibility = get_visibility(last_token.lexeme)

    token = consume(Syntax::Class)
    unless @within_class.nil?
      Logger.report_error("Invalid class", "Classes may not be nested", token)
    end

    identifier = consume(Syntax::Identifier)

    # superclass
    if match?(Syntax::Colon)
      superclass = Expression::Var.new(consume(Syntax::Identifier))
    end

    if check?(Syntax::Comma)
      Logger.report_error("Invalid class definition", "A class may only have one superclass", current)
    end

    # mixin
    if match?(Syntax::Mixin)
      mixins = comma_separated do
        Expression::Var.new(consume(Syntax::Identifier))
      end
    end

    @within_class = identifier.lexeme
    body = parse_block
    @within_class = nil

    mixins ||= [] of Expression::Var
    Statement::ClassDef.new(identifier, body, visibility, superclass, mixins)
  end

  private def parse_when_statement : Statement::When
    token = last_token
    conditions = comma_separated do
      type_info = parse_type(required: false)

      # we're comparing a value
      if type_info[:type_ref].nil?
        parse_expression
      else # we're comparing a type
        type_info[:type_ref].not_nil!
      end
    end

    consume(Syntax::FatArrow)
    block = parse_statement
    Statement::When.new(token, conditions, block)
  end

  private def parse_case_statement : Statement::Case
    token = last_token
    value = parse_expression
    consume(Syntax::LBrace)

    comparisons = [] of Statement::When
    while match?(Syntax::When)
      comparisons << parse_when_statement
    end

    if match?(Syntax::Else)
      consume(Syntax::FatArrow)
      else_block = parse_statement
    end

    consume(Syntax::RBrace)
    Statement::Case.new(token, value, comparisons, else_block)
  end

  private def parse_every_statement : Statement::Every
    token = last_token
    type_info = parse_type

    if type_info[:type_ref].nil?
      Logger.report_error("Expected typedef, got", last_token.lexeme, last_token)
    end
    typedef = type_info[:type_ref].not_nil!.name

    ident = consume(Syntax::Identifier)
    var = Expression::Var.new(ident)
    var_declaration = Expression::VarDeclaration.new(
      typedef, var,
      Expression::NoneLiteral.new(nil, ident),
      class_field: !@within_class.nil?,
      mutable: false,
      visibility: Visibility::Private
    )

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

  private def parse_try_catch_statement : Statement::TryCatch
    enclosing_class = @within_class
    @within_class = nil

    try_keyword = last_token
    try_block = parse_statement
    catch_keyword = consume(Syntax::Catch)

    type_info = parse_type
    if type_info[:type_ref].nil?
      Logger.report_error("Expected typedef, got", last_token.lexeme, last_token)
    end
    typedef = type_info[:type_ref].not_nil!.name

    @within_class = enclosing_class
    ident = consume(Syntax::Identifier)
    var = Expression::Var.new(ident)
    var_declaration = Expression::VarDeclaration.new(
      typedef, var,
      Expression::NoneLiteral.new(nil, ident),
      class_field: !@within_class.nil?,
      mutable: false,
      visibility: Visibility::Private
    )

    enclosing_class = @within_class
    @within_class = nil
    catch_block = parse_statement
    got_finally = match?(Syntax::Finally)
    @within_class = enclosing_class

    Statement::TryCatch.new(
      try_keyword,
      catch_keyword,
      got_finally ? last_token : nil,
      try_block,
      catch_block,
      got_finally ? parse_statement : nil,
      var_declaration
    )
  end

  private def parse_use_statement : Statement::Use
    Statement::Use.new(consume(Syntax::String), peek -2)
  end

  private def parse_throw_statement : Statement::Throw
    keyword = last_token
    Statement::Throw.new(parse_expression, keyword)
  end

  private def parse_return_statement : Statement::Return
    value = check?(Syntax::RBrace) ? nil : parse_expression
    Statement::Return.new(value || Expression::NoneLiteral.new(nil, last_token), last_token)
  end

  private def parse_fn_def_statement : Statement::FunctionDef
    enclosing_class = @within_class
    @within_class = nil

    type_info = parse_type(required: true, check_visibility: true)
    return_typedef = type_info[:type_ref].not_nil!.name

    consume(Syntax::Function)
    function_ident = consume(Syntax::Identifier)

    if match?(Syntax::LParen)
      params = parse_fn_params
      consume(Syntax::RParen)
    end

    body = parse_block
    @within_class = enclosing_class

    Statement::FunctionDef.new(
      function_ident,
      params || [] of Expression::Parameter,
      body,
      return_typedef,
      type_info[:visibility],
      !@within_class.nil?
    )
  end

  # Parse function parameters and return an array of nodes
  private def parse_fn_params : Array(Expression::Parameter)
    params = [] of Expression::Parameter
    reached_spread = false

    type_info = parse_type(required: false, check_mut: true)
    if type_info[:found_typedef]
      enclosing = @not_assignment
      @not_assignment = true

      param_type = type_info[:type_ref].not_nil!.name
      is_mut = type_info[:is_mut]

      if reached_spread && check?(Syntax::Star)
        Logger.report_error("Invalid parameter", "Cannot define other parameters after spread parameter", last_token)
      end

      reached_spread = match?(Syntax::Star)
      param_ident = consume(Syntax::Identifier)

      if match?(Syntax::Equal)
        value = parse_expression
        params << Expression::Parameter.new(param_type, param_ident, is_mut, value, spread: reached_spread)
      else
        params << Expression::Parameter.new(param_type, param_ident, is_mut, spread: reached_spread)
      end

      while match?(Syntax::Comma)
        type_info = parse_type(required: true, check_mut: true)
        param_type = type_info[:type_ref].not_nil!.name
        is_mut = type_info[:is_mut]

        if reached_spread && check?(Syntax::Star)
          Logger.report_error("Invalid parameter", "Cannot define other parameters after spread parameter", last_token)
        end

        reached_spread = match?(Syntax::Star)
        param_ident = consume(Syntax::Identifier)

        if match?(Syntax::Equal)
          value = parse_expression
          params << Expression::Parameter.new(param_type, param_ident, is_mut, value, spread: reached_spread)
        else
          params << Expression::Parameter.new(param_type, param_ident, is_mut, spread: reached_spread)
        end
      end

      @not_assignment = enclosing
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

  private ACCESS_SYNTAXES = Set.new([Syntax::ColonColon, Syntax::Dot, Syntax::HyphenArrow])
  private def parse_after(expr : Expression::Base) : Expression::Base
    callee = expr

    if match?(Syntax::LParen)
      enclosing = @not_assignment
      @not_assignment = true

      arguments = [] of Expression::Base
      until match?(Syntax::RParen)
        arguments << parse_expression
        match?(Syntax::Comma)
      end

      @not_assignment = enclosing
      callee = Expression::FunctionCall.new(callee, arguments)
    elsif match?(Syntax::LBracket)
      key = parse_expression
      consume(Syntax::RBracket)
      nullable = match?(Syntax::Question)
      callee = Expression::Index.new(callee, key, nullable)
    elsif token_exists? && ACCESS_SYNTAXES.includes?(current.type) ||
      (token_exists? && token_exists?(1) &&
      current.type == Syntax::Ampersand &&
      ACCESS_SYNTAXES.includes?(peek.type)) # it's a property access

      nullable = consume_current.type == Syntax::Ampersand
      consume_current if nullable

      key = consume(Syntax::Identifier)
      callee = Expression::Access.new(callee, key, nullable)
    end

    if token_exists? && (current.type == Syntax::LBracket || current.type == Syntax::LParen || ACCESS_SYNTAXES.includes?(current.type))
      callee = parse_after(callee)
    end

    callee
  end

  private def get_visibility(lexeme : String?) : Visibility
    case lexeme
    when "public"
      visibility = Visibility::Public
    when "private"
      visibility = Visibility::Private
    when "protected"
      visibility = Visibility::Protected
    when "static"
      visibility = Visibility::Static
    else
      visibility = Visibility::Private
    end

    visibility
  end

  private alias TypeInfo = NamedTuple(
    found_typedef: Bool,
    variable_type: Token?,
    type_ref: Expression::TypeRef?,
    is_mut: Bool,
    is_nullable: Bool,
    visibility: Visibility
  )

  # i dont wanna talk about this method
  # or the one below it
  private def parse_type(
    required : Bool = true,
    check_mut : Bool = false,
    check_visibility : Bool = false,
    paren_depth : Int = 0
  ) : TypeInfo

    is_nullable = false
    if check_visibility
      has_visibility = match?(Syntax::Public) || match?(Syntax::ClassVisibility)
      visibility_lexeme = last_token.lexeme
    end

    visibility = get_visibility(visibility_lexeme)
    is_mut = match?(Syntax::Mut) if check_mut
    if check?(Syntax::LParen) &&
      token_exists?(1) && (peek.type == Syntax::TypeDef || peek.type == Syntax::Identifier) &&
      token_exists?(2) && (peek(2).type == Syntax::Identifier ||
      peek(2).type == Syntax::Pipe ||
      peek(2).type == Syntax::HyphenArrow ||
      peek(2).type == Syntax::LBracket ||
      peek(2).type == Syntax::RParen)

      consume(Syntax::LParen)
      info = parse_type(required: required, paren_depth: paren_depth + 1)
      consume(Syntax::RParen)

      variable_type, type_ref = parse_type_suffix(info[:variable_type].not_nil!, required, paren_depth)
      return {
        found_typedef: info[:found_typedef],
        variable_type: variable_type,
        type_ref: type_ref,
        is_mut: is_mut || false,
        is_nullable: info[:is_nullable],
        visibility: visibility.not_nil!
      }
    end

    if required
      consume(Syntax::Identifier) unless match?(Syntax::TypeDef)
      found_typedef = true
      variable_type = last_token
    else
      found_registered_type = token_exists? &&
        current.type == Syntax::Identifier &&
        !TypeChecker.get_registered_type?(current.lexeme, current).nil?

      found_typedef = found_registered_type || match?(Syntax::TypeDef)
      variable_type = found_registered_type ? consume_current : last_token if found_typedef
    end

    unless variable_type.nil?
      variable_type, type_ref = parse_type_suffix(variable_type, required, paren_depth)
    end

    {
      found_typedef: found_typedef,
      variable_type: variable_type,
      type_ref: type_ref,
      is_mut: is_mut || false,
      is_nullable: is_nullable,
      visibility: visibility.not_nil!
    }
  end

  private def parse_type_suffix(variable_type : Token, required : Bool = true, paren_depth : Int = 0) : Tuple(Token, Expression::TypeRef)
    type_ref = Expression::TypeRef.new(variable_type)

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
      if token_exists? && current.type == Syntax::Question
        Logger.report_error("Invalid type", "Type can only be made nullable once", current)
      end
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

    if cur.type == Syntax::Mut ||
      cur.type == Syntax::Public ||
      cur.type == Syntax::ClassVisibility ||
      cur.type == Syntax::LParen

      at_fn_type?(offset: offset + 1) ## skip the token
    else
      if peeked.type == Syntax::LBracket && !next_peeked.nil? && next_peeked.type == Syntax::RBracket
        return at_fn_type?(offset: offset + 2)
      end
      if peeked.type == Syntax::Question || peeked.type == Syntax::RParen
        return at_fn_type?(offset: offset + 1)
      end

      if (peeked.type == Syntax::Pipe || peeked.type == Syntax::HyphenArrow) &&
        !next_peeked.nil? &&
        (next_peeked.type == Syntax::TypeDef || next_peeked.type == Syntax::Identifier)

        return at_fn_type?(offset: offset + 2)
      end

      peeked.type == Syntax::Function
    end
  end

  private def parse_type_alias(type_token : Token, identifier : Expression::Var) : Expression::TypeAlias
    consume(Syntax::Equal)
    type_info = parse_type(required: true, check_visibility: true, check_mut: true)
    type_ref = type_info[:type_ref].not_nil!
    TypeChecker.alias_type(identifier.token.lexeme, type_ref.name.lexeme)

    Expression::TypeAlias.new(
      type_token,
      identifier,
      type_ref,
      type_info[:is_mut],
      type_info[:visibility]
    )
  end

  # Parse a variable declaration and return a node
  private def parse_var_declaration : Expression::Base
    type_info = parse_type(
      required: false,
      check_mut: true,
      check_visibility: true
    )

    unless type_info[:type_ref].nil?
      typedef = type_info[:type_ref].not_nil!.name

      if match?(Syntax::Identifier)
        variable_name = last_token
        if variable_name.lexeme.ends_with?("?")
          Logger.report_error("Invalid identifier '#{variable_name.lexeme}'", "Only function identifiers may include a '?' character", variable_name)
        elsif variable_name.lexeme.ends_with?("!")
          Logger.report_error("Invalid identifier '#{variable_name.lexeme}'", "Only function identifiers may include a '!' character", variable_name)
        end

        identifier = Expression::Var.new(variable_name)
        if typedef.value == "type"
          parse_type_alias(typedef, identifier)
        else
          if check?(Syntax::Comma) && !@not_assignment
            return parse_multiple_declaration(typedef, identifier, type_info)
          end
          if match?(Syntax::Equal)
            value = parse_expression
            Expression::VarDeclaration.new(
              typedef, identifier, value,
              class_field: !@within_class.nil?,
              mutable: type_info[:is_mut],
              visibility: type_info[:visibility]
            )
          else
            first = Expression::VarDeclaration.new(
              typedef, identifier,
              Expression::NoneLiteral.new(nil, variable_name),
              class_field: !@within_class.nil?,
              mutable: type_info[:is_mut],
              visibility: type_info[:visibility]
            )

            first
          end
        end
      else
        Logger.report_error("Expected identifier, got", token_exists? ? current.lexeme : "EOF", token_exists? ? current : last_token)
      end
    else
      parse_assignment
    end
  end

  private def parse_multiple_declaration(
    typedef : Token,
    expr : Expression::Var,
    type_info : TypeInfo
  ) : Expression::MultipleDeclaration

    location_commas = 0
    locations = [ expr ] of Expression::Var
    while match?(Syntax::Comma)
      consume(Syntax::Identifier)
      location_commas += 1
      locations << Expression::Var.new(last_token)
    end

    if match?(Syntax::Equal)
      enclosing = @not_assignment
      @not_assignment = true

      values = [ parse_expression ]
      consume(Syntax::Comma) # make sure there's at least one comma, since a multiple assignment requires at least one
      values << parse_expression

      value_commas = 1
      while match?(Syntax::Comma)
        value_commas += 1
        values << parse_expression
      end

      @not_assignment = enclosing
      unless location_commas == value_commas
        Logger.report_error(
          "Uneven multiple assignment",
          "The left side of this assignment has #{location_commas} commas while the right side has #{value_commas} commas",
          values.last.token
        )
      end
    end

    nodes = [] of Expression::VarDeclaration
    locations.each_with_index do |var, i|
      respective_value = (!values.nil? ? values[i]? : nil) || Expression::NoneLiteral.new(nil, var.token)
      nodes << Expression::VarDeclaration.new(
        typedef, var,
        respective_value,
        class_field: !@within_class.nil?,
        mutable: type_info[:is_mut],
        visibility: type_info[:visibility]
      )
    end

    Expression::MultipleDeclaration.new(nodes)
  end

  private alias AssignmentLocation = Expression::Var | Expression::Index | Expression::Access
  private def assert_assignment_location(expr : Expression::Base, token : Token = expr.token)
    unless expr.is_a?(AssignmentLocation)
      Logger.report_error("Expected identifier or property, got", token.lexeme, token)
    end
  end

  private def parse_multiple_assignment(expr : Expression::Base) : Expression::MultipleAssignment
    assert_assignment_location(expr)

    location_commas = 0
    locations = [ expr ] of AssignmentLocation
    while match?(Syntax::Comma)
      location_commas += 1
      location = parse_assignment(match_equal: false, check_comma: false)
      assert_assignment_location(location)
      locations << location
    end

    consume(Syntax::Equal)
    enclosing = @not_assignment
    @not_assignment = true
    values = [ parse_expression ]
    consume(Syntax::Comma) # make sure there's at least one comma, since a multiple assignment requires at least one
    values << parse_expression

    value_commas = 1
    while match?(Syntax::Comma)
      value_commas += 1
      values << parse_expression
    end

    @not_assignment = enclosing
    unless location_commas == value_commas
      Logger.report_error(
        "Uneven multiple assignment",
        "The left side of this assignment has #{location_commas} commas while the right side has #{value_commas} commas",
        values.last.token
      )
    end

    nodes = [] of Expression::VarAssignment | Expression::PropertyAssignment
    locations.each_with_index do |loc, i|
      respective_value = values[i]
      if loc.is_a?(Expression::Var)
        nodes << Expression::VarAssignment.new(loc, respective_value)
      elsif loc.is_a?(Expression::Index) || loc.is_a?(Expression::Access)
        nodes << Expression::PropertyAssignment.new(loc, respective_value)
      else
        Logger.report_error("Invalid assignment target", "Attempt to assign to '#{loc.token.lexeme}'", loc.token)
      end
    end

    Expression::MultipleAssignment.new(nodes)
  end

  # Parse a variable assignment expression and return a node
  private def parse_assignment(match_equal = true, check_comma = true) : Expression::Base
    left = parse_compound_assignment
    if check?(Syntax::Comma) && !@not_assignment && check_comma
      return parse_multiple_assignment(left)
    end

    if match_equal && match?(Syntax::Equal)
      value = parse_expression
      assert_assignment_location(left, peek -2)
      if left.is_a?(Expression::Var)
        left = Expression::VarAssignment.new(left, value)
      elsif left.is_a?(Expression::Index) || left.is_a?(Expression::Access)
        left = Expression::PropertyAssignment.new(left, value)
      else
        Logger.report_error("Invalid assignment target", "Attempt to assign to '#{left.token.lexeme}'", left.token)
      end
    end

    left
  end

  private def parse_compound_assignment : Expression::Base
    left = parse_logical_or

    if match?(Syntax::AndEqual) || match?(Syntax::OrEqual) ||
      match?(Syntax::QuestionColonEqual) ||
      match?(Syntax::CaratEqual) ||
      match?(Syntax::StarEqual) || match?(Syntax::SlashEqual) ||
      match?(Syntax::SlashSlashEqual) || match?(Syntax::PercentEqual) ||
      match?(Syntax::PlusEqual) || match?(Syntax::MinusEqual)

      op = last_token
      right = parse_logical_or
      unless left.is_a?(Expression::Var) ||
        left.is_a?(Expression::Access) ||
        left.is_a?(Expression::Index) ||

        Logger.report_error("Expected identifier or property, got", left.token.lexeme, left.token)
      end

      left = Expression::CompoundAssignment.new(left.as(Expression::Var | Expression::Index | Expression::Access), op, right)
    end

    left
  end

  # Parse a logical OR expression and return a node
  private def parse_logical_or : Expression::Base
    left = parse_logical_and

    while match?(Syntax::Or) || match?(Syntax::QuestionColon)
      op = last_token
      right = parse_logical_and
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a logical AND expression and return a node
  private def parse_logical_and : Expression::Base
    left = parse_comparison

    while match?(Syntax::And)
      op = last_token
      right = parse_comparison
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a comparison expression and return a node
  private def parse_comparison : Expression::Base
    left = parse_equality

    while match?(Syntax::Less) || match?(Syntax::LessEqual) || match?(Syntax::Greater) || match?(Syntax::GreaterEqual)
      op = last_token
      right = parse_equality
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an equality expression and return a node
  private def parse_equality : Expression::Base
    left = parse_bitwise_or

    while match?(Syntax::EqualEqual) || match?(Syntax::BangEqual) || match?(Syntax::Is)
      op = last_token
      if op.lexeme == "is"
        inversed = match?(Syntax::Not)
        type_info = parse_type
        left = Expression::Is.new(left, type_info[:type_ref].not_nil!, inversed)
      else
        right = parse_bitwise_or
        left = Expression::BinaryOp.new(left, op, right)
      end
    end

    left
  end

  # Parse a bitwise or expression and return a node
  private def parse_bitwise_or : Expression::Base
    left = parse_bitwise_and

    while match?(Syntax::Pipe)
      op = last_token
      right = parse_bitwise_and
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a bitwise and expression and return a node
  private def parse_bitwise_and : Expression::Base
    left = parse_shift

    while match?(Syntax::Ampersand)
      op = last_token
      right = parse_shift
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a bitwise shift expression and return a node
  private def parse_shift : Expression::Base
    left = parse_additive

    while match?(Syntax::RDoubleArrow) || match?(Syntax::LDoubleArrow)
      op = last_token
      right = parse_additive
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an additive expression and return a node
  private def parse_additive : Expression::Base
    left = parse_multiplicative

    while match?(Syntax::Plus) || match?(Syntax::Minus)
      op = last_token
      right = parse_multiplicative
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse a multiplicative expression and return a node
  private def parse_multiplicative : Expression::Base
    left = parse_exponential

    while match?(Syntax::Star) || match?(Syntax::Slash) ||
      match?(Syntax::SlashSlash) || match?(Syntax::Percent)

      op = last_token
      right = parse_exponential
      left = Expression::BinaryOp.new(left, op, right)
    end

    left
  end

  # Parse an exponential expression and return a node
  private def parse_exponential : Expression::Base
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
    if match?(Syntax::Plus) || match?(Syntax::Minus) ||
      match?(Syntax::PlusPlus) || match?(Syntax::MinusMinus) ||
      match?(Syntax::Not) || match?(Syntax::Star) ||
      match?(Syntax::Hashtag) || match?(Syntax::Tilde)

      op = last_token
      operand = parse_unary
      Expression::UnaryOp.new(op, operand)
    elsif match?(Syntax::Less)
      type_info = parse_type(
        required: true,
        check_mut: false,
        check_visibility: false
      )

      if type_info[:type_ref].nil?
        Logger.report_error("Failed to parse type", last_token.lexeme, last_token)
      end

      consume(Syntax::Greater)
      operand = parse_unary
      Expression::Cast.new(type_info[:type_ref].not_nil!, operand)
    else
      parse_after(parse_primary)
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
      Expression::Var.new(ident)
    elsif match?(Syntax::Ampersand)
      return_type_info = parse_type(check_mut: false, check_visibility: false)

      consume(Syntax::LParen)
      params = parse_fn_params
      consume(Syntax::RParen)
      consume(Syntax::Colon)
      body = parse_statement

      Expression::Lambda.new(params, body, return_type_info[:type_ref].not_nil!.name)
    elsif match?(Syntax::This)
      Expression::This.new(last_token)
    elsif match?(Syntax::New)
      token = last_token
      callee = parse_after(parse_primary)
      unless callee.is_a?(Expression::Var) || callee.is_a?(Expression::FunctionCall)
        Logger.report_error("Expected class name, got", callee.token.lexeme, callee.token)
      end

      Expression::New.new(token, callee)
    else
      parse_literal
    end
  end

  private def parse_table_key : Expression::Base
    if match?(Syntax::Identifier)
      Expression::StringLiteral.new(last_token.lexeme, last_token)
    elsif match?(Syntax::String)
      Expression::StringLiteral.new(last_token.lexeme, last_token)
    else
      Logger.report_error("Invalid table key", current.lexeme, current)
    end
  end

  private def parse_table_literal : Expression::TableLiteral
    enclosing = @not_assignment
    @not_assignment = true

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
    @not_assignment = enclosing

    Expression::TableLiteral.new(hash, last_token)
  end

  private def parse_vector_literal : Expression::VectorLiteral
    enclosing = @not_assignment
    @not_assignment = true

    elements = [] of Expression::Base
    until match?(Syntax::RBracket)
      elements << parse_expression
      match?(Syntax::Comma)
    end
    @not_assignment = enclosing

    Expression::VectorLiteral.new(elements, last_token)
  end

  private def extract_interpolation_parts(s : String) : Array(String)
    pattern = /\%(\{(?:[^{}]|(?R)|\{\{(?:[^{}]|(?R))*\}\})*\})/
    raw_parts = [] of String
    match = s.match(pattern)

    unless match.nil?
      raw_parts << match.pre_match
      raw_parts << match[0]
      if !!(pattern =~ match.post_match)
        raw_parts += extract_interpolation_parts(match.post_match)
      else
        raw_parts << match.post_match
      end
    end

    raw_parts
  end

  private def parse_string_interpolation : Expression::StringInterpolation
    string_token = last_token
    raw_parts = extract_interpolation_parts(string_token.lexeme)
    parts = [] of String | Expression::Base

    raw_parts.each do |part|
      if part.starts_with?("%{")
        interpolation_parser = Parser.new(part[2..-2], "interpolation:#{@file_path}", @run_benchmarks, @within_class)
        statements = interpolation_parser.parse
        unless statements.size == 1
          Logger.report_error("Invalid string interpolation", "Only one expression/statement can be used within an interpolation", string_token)
        end

        root = statements.first
        unless root.is_a?(Statement::SingleExpression)
          Logger.report_error("Invalid string interpolation", "Statements are not supported within an interpolation", string_token)
        end

        parts << root.expression
      else
        parts << part
      end
    end

    Expression::StringInterpolation.new(parts, string_token)
  end


  private alias LiteralExpression = Expression::Literal | Expression::RangeLiteral | Expression::Lambda | Expression::VectorLiteral | Expression::TableLiteral | Expression::StringInterpolation
  # Parse a number and return an AST node
  private def parse_literal : LiteralExpression
    unless token_exists?
      Logger.report_error("Expected literal, got", "EOF", last_token)
    end

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
      value = value.as Int
      if value > Int64::MAX
        Expression::BigIntLiteral.new(value.to_i128, last_token)
      else
        Expression::IntLiteral.new(value.to_i64, last_token)
      end
    when Syntax::Float
      consume_current
      Expression::FloatLiteral.new(value.as Float, last_token)
    when Syntax::Boolean
      consume_current
      Expression::BooleanLiteral.new(value.as Bool, last_token)
    when Syntax::String
      consume_current
      if value.to_s.includes?("%{")
        parse_string_interpolation
      else
        Expression::StringLiteral.new(value.to_s, last_token)
      end
    when Syntax::Char
      consume_current
      Expression::CharLiteral.new(value.as Char, last_token)
    when Syntax::None
      consume_current
      Expression::NoneLiteral.new(nil, last_token)
    else
      Logger.report_error("Invalid syntax", current.lexeme, current)
    end
  end

  # Returns a list of comma separated expressions
  private def comma_separated(& : -> R) : Array(R) forall R
    enclosing = @not_assignment
    @not_assignment = true

    expressions = [] of R
    expressions << yield
    while match?(Syntax::Comma)
      expressions << yield
    end

    @not_assignment = enclosing
    expressions
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

  # Returns whether or not the token at `offset`'s (default current) syntax is `syntax`
  private def check?(syntax : Syntax, offset : Int32 = 0) : Bool
    return false unless token_exists?(offset)
    peek(offset).type == syntax
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
  private def consume(syntax : Syntax) : Token
    unless token_exists?
      raise "Failed to consume: Token stream finished"
    end

    to_return = current
    got = current.type == Syntax::Identifier ? "identifier" : current.lexeme
    got = current.type == Syntax::TypeDef ? "type" : got
    Logger.report_error("Expected #{syntax}, got", got, current) unless current.type == syntax
    @position += 1

    to_return
  end

  # Consume the current token and advance the position
  private def consume_current : Token
    token = current
    @position += 1
    token
  end
end
