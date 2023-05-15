require "../syntax/parser"; include Cosmo::AST
require "./function"
require "./scope"
require "./operator"
require "./type"

class Cosmo::Return < Exception
  getter value : ValueType

  def initialize(@value, token : Token)
    super "[#{token.location.line}:#{token.location.position + 1}] Invalid return: A return statement can only be used within a function body"
  end
end

class Cosmo::Interpreter
  include Expression::Visitor(ValueType)
  include Statement::Visitor(ValueType)

  getter? output_ast = false
  getter file_path : String = ""
  getter globals = Scope.new
  getter scope : Scope
  @locals = {} of Expression::Base => UInt32
  @meta = {} of String => String

  private def declare_intrinsic(type : String, ident : String, value : ValueType)
    location = Location.new("intrinsic", 0, 0)
    ident_token = Token.new(Syntax::Identifier, ident, location)
    typedef_token = Token.new(Syntax::TypeDef, type, location)
    @globals.declare(typedef_token, ident_token, value)
  end

  def initialize(@output_ast)
    TypeChecker.register_intrinsics

    @scope = @globals
    declare_intrinsic("fn", "puts", PutsIntrinsic.new)

    version = "Cosmo v#{`shards version`}".strip
    declare_intrinsic("string", "__version", version)
  end

  def interpret(source : String, @file_path : String) : ValueType
    parser = Parser.new(source, @file_path)
    statements = parser.parse
    puts statements.map(&.to_s) if @output_ast

    # init resolver here

    result = nil
    statements.each do |stmt|
      result = execute(stmt)
    end
    result
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
        token = return_node.nil? ? Token.new(Syntax::None, nil, Location.new("", 0, 0)) : return_node.token
        TypeChecker.assert(return_type, return_value, token)
      end
      return_value
    rescue ex : Exception
      raise ex
    ensure
      @scope = prev_scope
    end
  end

  def visit_until_stmt(stmt : Statement::Until) : Nil
    until evaluate(stmt.condition)
      execute(stmt.block)
    end
  end

  def visit_while_stmt(stmt : Statement::While) : Nil
    while evaluate(stmt.condition)
      execute(stmt.block)
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

  def visit_index_expr(expr : Expression::Index) : ValueType
    ref = evaluate(expr.ref)
    unless ref.is_a?(Array)
      Logger.report_error("Attempt to index", TypeChecker.get_mapped(ref.class), expr.ref.token)
    end
    key = evaluate(expr.key)
    if key.is_a?(Int)
      ref[key]
    else
      Logger.report_error("Invalid index type", TypeChecker.get_mapped(key.class), expr.ref.token)
    end
  end

  def visit_vector_literal_expr(expr : Expression::VectorLiteral) : Array(ValueType)
    expr.values.map { |v| evaluate(v) }
  end

  def visit_type_ref_expr(expr : Expression::TypeRef) : Type
    TypeChecker.get_registered_type(expr.name.value.to_s, expr.name)
  end

  def visit_type_alias_expr(expr : Expression::TypeAlias) : Nil
    value = evaluate(expr.value.as Expression::Base)
    @scope.declare(expr.type_token, expr.token, value)
  end

  def visit_return_stmt(stmt : Statement::Return) : Nil
    value = evaluate(stmt.value)
    raise Return.new(value, stmt.keyword)
  end

  def visit_fn_def_stmt(stmt : Statement::FunctionDef) : ValueType
    typedef = Token.new(Syntax::TypeDef, "fn", Location.new(@file_path, 0, 0))
    fn = Function.new(self, @scope, stmt)
    @scope.declare(typedef, stmt.identifier, fn)
    fn
  end

  def visit_fn_call_expr(expr : Expression::FunctionCall) : ValueType
    fn = @scope.lookup(expr.var.token)
    unless fn.is_a?(Function) || fn.is_a?(IntrinsicFunction)
      Logger.report_error("Attempt to call", TypeChecker.get_mapped(fn.class), expr.var.token)
    end
    unless fn.arity.includes?(expr.arguments.size)
      Logger.report_error("Expected #{fn.arity} arguments, got", expr.arguments.size.to_s, expr.var.token)
    end

    @meta["block_return_type"] = fn.definition.return_typedef.value.to_s unless fn.is_a?(IntrinsicFunction)
    arg_values = expr.arguments.map { |arg| evaluate(arg.as Expression::Base) }
    fn.call(arg_values)
  end

  def visit_var_expr(expr : Expression::Var) : ValueType
    @scope.lookup(expr.token)
  end

  def visit_var_declaration_expr(expr : Expression::VarDeclaration) : ValueType
    value = evaluate(expr.value.as Expression::Base)
    @scope.declare(expr.typedef, expr.var.token, value)
  end

  def visit_var_assignment_expr(expr : Expression::VarAssignment) : ValueType
    value = evaluate(expr.value.as Expression::Base)
    @scope.assign(expr.var.token, value)
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
    left = evaluate(expr.left.as Expression::Base)
    right = evaluate(expr.right.as Expression::Base)
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
