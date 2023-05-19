require "../syntax/parser"; include Cosmo::AST
require "./hooked_exceptions"
require "./function"
require "./scope"
require "./operator"
require "./type"
require "./resolver"
require "./lib/math"

class Cosmo::Interpreter
  include Expression::Visitor(ValueType)
  include Statement::Visitor(ValueType)

  getter globals = Scope.new
  getter scope : Scope
  @locals = {} of Expression::Base => UInt32
  @meta = {} of String => String
  @file_path : String = ""

  def initialize(
    @output_ast : Bool,
    @run_benchmarks : Bool,
    debug_mode : Bool
  )
    Logger.debug = debug_mode
    TypeChecker.register_intrinsics

    @scope = @globals


    MathLib.inject(self)
    declare_intrinsic("func", "puts", PutsIntrinsic.new(self))

    version = "Cosmo v#{`shards version`}".strip
    declare_intrinsic("string", "__version", version)
  end

  def declare_intrinsic(type : String, ident : String, value : ValueType)
    location = Location.new("intrinsic", 0, 0)
    ident_token = Token.new(ident, Syntax::Identifier, ident, location)
    typedef_token = Token.new(type, Syntax::TypeDef, type, location)
    @globals.declare(typedef_token, ident_token, value, const: true)
  end

  def set_meta(key : String, value : String?) : Nil
    return if value.nil?
    @meta[key] = value
  end

  def interpret(source : String, @file_path : String) : ValueType
    parser = Parser.new(source, @file_path, @run_benchmarks)
    statements = parser.parse

    statement_list_str = ""
    statements.each do |stmt|
      statement_list_str += stmt.to_s + "\n"
    end

    puts statement_list_str if @output_ast

    resolver = Resolver.new(self)
    resolver.resolve(statements)
    end_time = Time.monotonic
    puts "Resolver took #{get_elapsed(resolver.start_time, end_time)}." if @run_benchmarks

    start_time = Time.monotonic

    result = nil
    statements.each do |stmt|
      result = execute(stmt)
    end

    # Check if "main" fn exists and call it
    main_fn = @globals.lookup?(Token.new("main", Syntax::Identifier, "main", Location.new("", 0, 0)))
    found_main = !main_fn.nil? && main_fn.is_a?(Function)
    if found_main
      main_fn = main_fn.as(Function)
      return_typedef = main_fn.definition.return_typedef
      @meta["block_return_type"] = return_typedef.value.to_s
      main_result = main_fn.call([ARGV.size, ARGV.map(&.as ValueType)])
      TypeChecker.assert("int", main_result, return_typedef)
    end

    end_time = Time.monotonic
    puts "Interpreter took #{get_elapsed(start_time, end_time)}." if @run_benchmarks

    if found_main && @file_path != "test" && @file_path != "repl"
      code = main_result.not_nil!.as(Int64)
      if code == 0 # success
        Process.exit(code)
      else
        raise "Process exited with code #{code}"
      end
    end

    result
  end

  def resolve(expr : Expression::Base, depth : UInt32) : Nil
    @locals[expr] = depth
  end

  private def lookup_variable(identifier : Token, expr : Expression::Base) : ValueType
    distance : UInt32? = @locals[expr]?
    return @scope.lookup_at(distance, identifier) unless distance.nil?
    @globals.lookup(identifier)
  end

  def evaluate(expr : Expression::Base) : ValueType
    expr.accept(self)
  end

  def execute(stmt : Statement::Base) : ValueType
    stmt.accept(self)
  end

  def execute_block(block : Statement::Block, block_scope : Scope, is_fn : Bool = false) : ValueType
    prev_scope = @scope
    begin
      @scope = block_scope
      unless block.nodes.empty?
        return_node = block.nodes.find { |node| node.is_a?(Statement::Return) } || block.nodes.last
        body_nodes = block.nodes[0..-2]
        body_nodes.each { |expr| execute(expr.as Statement::Base) }
        return_value = execute(return_node.as Statement::Base) unless return_node.nil?
      end
      if is_fn
        return_type = @meta["block_return_type"]? || "void"
        token = return_node.nil? ? Token.new("none", Syntax::None, nil, Location.new("", 0, 0)) : return_node.token
        TypeChecker.assert(return_type, return_value, token)
      end
      return_value
    rescue ex : Exception
      raise ex
    ensure
      @scope = prev_scope
    end
  end

  def visit_every_stmt(stmt : Statement::Every) : Nil
    enclosing = @scope
    @scope = Scope.new(@scope)

    enumerable = evaluate(stmt.enumerable)

    @scope.declare(stmt.var.typedef, stmt.var.token, nil)
    if enumerable.is_a?(Array) || enumerable.is_a?(Range)
      enumerable.each do |value|
        @scope.assign(stmt.var.token, value)
        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break
        rescue _next : HookedExceptions::Next
          next
        end
      end
    elsif enumerable.is_a?(String)
      enumerable.chars.each do |value|
        @scope.assign(stmt.var.token, value)
        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break
        rescue _next : HookedExceptions::Next
          next
        end
      end
    elsif enumerable.is_a?(Callable)
      if enumerable.is_a?(IntrinsicFunction)
        Logger.report_error("Invalid iterator", "An iterator cannot be an intrinsic function", stmt.enumerable.token)
      end
      unless enumerable.is_a?(Function)
        Logger.report_error("Invalid iterator", "An iterator must return a generator function", stmt.enumerable.token)
      end

      # keep looping until the iterator returns none
      until (value = enumerable.call([] of ValueType)).nil?
        @scope.assign(stmt.var.token, value)
        begin
          execute_block(stmt.block, scope)
        rescue _break : HookedExceptions::Break
          break
        rescue _next : HookedExceptions::Next
          next
        end
      end
    else
      Logger.report_error("Invalid iterator type", TypeChecker.get_mapped(enumerable.class), stmt.token)
    end

    @scope = enclosing
  end

  def visit_next_stmt(stmt : Statement::Next) : Nil
    raise HookedExceptions::Next.new(stmt.keyword)
  end

  def visit_break_stmt(stmt : Statement::Break) : Nil
    raise HookedExceptions::Break.new(stmt.keyword)
  end

  def visit_return_stmt(stmt : Statement::Return) : Nil
    value = evaluate(stmt.value)
    raise HookedExceptions::Return.new(value, stmt.keyword)
  end

  def visit_until_stmt(stmt : Statement::Until) : Nil
    until evaluate(stmt.condition)
      begin
        execute(stmt.block)
      rescue _break : HookedExceptions::Break
        break
      rescue _next : HookedExceptions::Next
        next
      end
    end
  end

  def visit_while_stmt(stmt : Statement::While) : Nil
    while evaluate(stmt.condition)
      begin
        execute(stmt.block)
      rescue _break : HookedExceptions::Break
        break
      rescue _next : HookedExceptions::Next
        next
      end
    end
  end

  def visit_unless_stmt(stmt : Statement::Unless) : ValueType
    condition = evaluate(stmt.condition)
    unless condition
      execute(stmt.then)
    else
      execute(stmt.else.not_nil!) unless stmt.else.nil?
    end
  end

  def visit_if_stmt(stmt : Statement::If) : ValueType
    condition = evaluate(stmt.condition)
    if condition
      execute(stmt.then)
    else
      execute(stmt.else.not_nil!) unless stmt.else.nil?
    end
  end

  def visit_fn_def_stmt(stmt : Statement::FunctionDef) : ValueType
    fn = Function.new(self, @scope, stmt)
    typedef = Token.new("func", Syntax::TypeDef, "func", Location.new(@file_path, 0, 0))
    @scope.declare(typedef, stmt.identifier, fn)
  end

  def visit_access_expr(expr : Expression::Access) : ValueType
    object = evaluate(expr.object)
    key = expr.key.value.to_s
    if object.is_a?(Hash)
      object[key]?
    else
      Logger.report_error("Attempt to index", TypeChecker.get_mapped(object.class), expr.token)
    end
  end

  def visit_index_expr(expr : Expression::Index) : ValueType
    object = evaluate(expr.object)
    key = evaluate(expr.key)

    if object.is_a?(String) || object.is_a?(Array)
      unless key.is_a?(Int)
        Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), expr.token)
      end
      object[key]?
    elsif object.is_a?(Hash)
      object[key]?
    else
      Logger.report_error("Attempt to index", TypeChecker.get_mapped(object.class), expr.token)
    end
  end

  def visit_type_ref_expr(expr : Expression::TypeRef) : Type
    TypeChecker.get_registered_type(expr.name.value.to_s, expr.name)
  end

  def visit_type_alias_expr(expr : Expression::TypeAlias) : Nil
    value = evaluate(expr.value.as Expression::Base)
    @scope.declare(expr.type_token, expr.token, value)
  end

  def visit_fn_call_expr(expr : Expression::FunctionCall) : ValueType
    fn = evaluate(expr.callee)
    unless fn.is_a?(Function) || fn.is_a?(IntrinsicFunction)
      Logger.report_error("Attempt to call", TypeChecker.get_mapped(fn.class), expr.token)
    end
    unless fn.arity.includes?(expr.arguments.size)
      arg_size = fn.arity.begin == fn.arity.end ? fn.arity.begin : fn.arity.to_s
      Logger.report_error("Expected #{arg_size} arguments, got", expr.arguments.size.to_s, expr.token)
    end

    arg_values = expr.arguments.map { |arg| evaluate(arg) }
    enclosing_return_type = @meta["block_return_type"]?
    result = fn.call(arg_values)
    set_meta("block_return_type", enclosing_return_type)
    result
  end

  def visit_var_expr(expr : Expression::Var) : ValueType
    @scope.lookup(expr.token)
  end

  def visit_var_declaration_expr(expr : Expression::VarDeclaration) : ValueType
    value = evaluate(expr.value)
    if expr.constant?
      @scope.declare(expr.typedef, expr.var.token, value, const: true)
    else
      @scope.declare(expr.typedef, expr.var.token, value)
    end
  end

  def visit_var_assignment_expr(expr : Expression::VarAssignment) : ValueType
    value = evaluate(expr.value)
    @scope.assign(expr.var.token, value)
  end

  def add_object_value(token : Token, object : V, key : ValueType, value : ValueType) : V forall V
    if object.is_a?(Array)
      unless key.is_a?(Int)
        Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), token)
      end
      object.insert(key, value)
    elsif object.is_a?(Hash)
      object[key] = value
    else
      Logger.report_error("Attempt to assign to index of", TypeChecker.get_mapped(object.class), token)
    end
    object
  end

  def visit_property_assignment_expr(expr : Expression::PropertyAssignment) : ValueType
    if expr.object.is_a?(Expression::Index)
      index = expr.object.as Expression::Index
      object_node = index.object
      key = evaluate(index.key)
      object = evaluate(object_node)
    else
      access = expr.object.as Expression::Access
      object_node = access.object
      key = access.key.lexeme
      object = evaluate(object_node)
    end

    value = expr.value.is_a?(Expression::Base) ?
      evaluate(expr.value.as Expression::Base)
      : expr.value.as ValueType

    if object_node.is_a?(Expression::Index) || object_node.is_a?(Expression::Access)
      object = add_object_value(expr.token, object, key, value)
      prop_assignment = Expression::PropertyAssignment.new(object_node, object)
      return visit_property_assignment_expr(prop_assignment)
    end

    object = add_object_value(expr.token, object, key, value)
    @scope.assign(expr.token, object)
  end

  def visit_compound_assignment_expr(expr : Expression::CompoundAssignment) : ValueType
    case expr.operator.type
    when Syntax::PlusEqual
      op = Operator::PlusAssign.new(self)
      op.apply(expr)
    when Syntax::MinusEqual
      op = Operator::MinusAssign.new(self)
      op.apply(expr)
    when Syntax::StarEqual
      op = Operator::MulAssign.new(self)
      op.apply(expr)
    when Syntax::SlashEqual
      op = Operator::DivAssign.new(self)
      op.apply(expr)
    when Syntax::PercentEqual
      op = Operator::ModAssign.new(self)
      op.apply(expr)
    when Syntax::CaratEqual
      op = Operator::PowAssign.new(self)
      op.apply(expr)
    end
  end

  def visit_ternary_op_expr(expr : Expression::TernaryOp) : ValueType
    condition = evaluate(expr.condition)

    return evaluate(expr.then) if condition
    evaluate(expr.else)
  end

  def visit_unary_op_expr(expr : Expression::UnaryOp) : ValueType
    operand = evaluate(expr.operand.as Expression::Base)
    case expr.operator.type
    when Syntax::Plus
      if operand.is_a?(Float) || operand.is_a?(Int)
        operand.abs
      else
        Logger.report_error("Invalid '+' operand type", operand.class.to_s, expr.operator)
      end
    when Syntax::Minus
      if operand.is_a?(Float) || operand.is_a?(Int)
        -operand
      else
        Logger.report_error("Invalid '-' operand type", operand.class.to_s, expr.operator)
      end
    when Syntax::Bang
      !operand
    when Syntax::Star
      raise "'*' unary operator has not yet implemented."
    when Syntax::Hashtag
      raise "'#' unary operator has not yet implemented."
    end
  end

  def visit_binary_op_expr(expr : Expression::BinaryOp) : ValueType
    left = evaluate(expr.left)
    right = evaluate(expr.right)

    case expr.operator.type
    when Syntax::Plus
      op = Operator::Plus.new(self)
      op.apply(expr)
    when Syntax::Minus
      op = Operator::Minus.new(self)
      op.apply(expr)
    when Syntax::Star
      op = Operator::Mul.new(self)
      op.apply(expr)
    when Syntax::Slash
      op = Operator::Div.new(self)
      op.apply(expr)
    when Syntax::Carat
      op = Operator::Pow.new(self)
      op.apply(expr)
    when Syntax::Percent
      op = Operator::Mod.new(self)
      op.apply(expr)
    when Syntax::Ampersand
      left && right
    when Syntax::Pipe
      left || right
    when Syntax::EqualEqual
      left == right
    when Syntax::BangEqual
      left != right
    when Syntax::Less
      op = Operator::LT.new(self)
      op.apply(expr)
    when Syntax::LessEqual
      op = Operator::LTE.new(self)
      op.apply(expr)
    when Syntax::Greater
      op = Operator::GT.new(self)
      op.apply(expr)
    when Syntax::GreaterEqual
      op = Operator::GTE.new(self)
      op.apply(expr)
    end
  end

  def visit_range_literal_expr(expr : Expression::RangeLiteral) : Range(Int64 | Int32 | Int16 | Int8, Int64 | Int32 | Int16 | Int8)
    from = evaluate(expr.from)
    to = evaluate(expr.to)

    unless from.is_a?(Int)
      Logger.report_error("Invalid left side of range literal", "Ranges can only be of integers, got '#{TypeChecker.get_mapped(from.class)}'", expr.token)
    end
    unless to.is_a?(Int)
      Logger.report_error("Invalid right side of range literal", "Ranges can only be of integers, got '#{TypeChecker.get_mapped(to.class)}'", expr.token)
    end

    from..to
  end

  def visit_table_literal_expr(expr : Expression::TableLiteral) : Hash(ValueType, ValueType)
    hash = {} of  ValueType => ValueType
    expr.hashmap.each do |k, v|
      key = evaluate(k)
      value = evaluate(v)
      hash[key] = value
    end
    hash
  end

  def visit_vector_literal_expr(expr : Expression::VectorLiteral) : Array(ValueType)
    expr.values.map { |v| evaluate(v) }
  end

  def visit_literal_expr(expr : Expression::Literal) : ValueType
    expr.value
  end

  def visit_single_expr_stmt(stmt : Statement::SingleExpression) : ValueType
    evaluate(stmt.expression)
  end

  def visit_block_stmt(stmt : Statement::Block) : ValueType
    execute_block(stmt, Scope.new(@scope))
  end
end
