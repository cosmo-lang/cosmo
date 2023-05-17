enum FnType
  None
  Fn
end

class Cosmo::Resolver
  include Expression::Visitor(Nil)
  include Statement::Visitor(Nil)

  @scopes = [] of Hash(String, Bool)
  @current_fn = FnType::None
  getter start_time : Time::Span

  def initialize(@interpreter : Interpreter)
    @start_time = Time.monotonic
  end

  def resolve(statements : Expression::Base | Statement::Base | Array(Statement::Base)) : Nil
    if statements.is_a?(Array)
      statements.each { |stmt| resolve(stmt) }
    else
      statements.accept(self)
    end
  end

  private def resolve_fn(fn : Statement::FunctionDef, type : FnType) : Nil
    enclosing_fn = @current_fn
    @current_fn = type

    begin_scope
    fn.parameters.each do |param|
      declare(param.identifier)
      define(param.identifier)
    end

    resolve(fn.body)
    end_scope

    @current_fn = enclosing_fn
  end

  private def resolve_local(expr : Expression::Base, name : Token) : Nil
    i = @scopes.size
    while i >= 0
      if !@scopes[i]?.nil? && @scopes[i].has_key?(name.lexeme)
        @interpreter.resolve(expr, (@scopes.size - i).to_u)
      end
      i -= 1
    end
  end

  private def begin_scope : Nil
    @scopes << {} of String => Bool
  end

  private def end_scope : Nil
    @scopes.pop
  end

  private def declare(name : Token) : Nil
    return if @scopes.empty?

    scope = @scopes.last
    unless scope.nil?
      Logger.report_error("Variable already declared in scope", name.lexeme, name) if scope.has_key?(name.lexeme)
      scope[name.lexeme] = false
    end
  end

  private def define(name : Token) : Nil
    return if @scopes.empty?
    scope = @scopes.last
    scope[name.lexeme] = true unless scope.nil?
  end

  def visit_block_stmt(stmt : Statement::Block) : Nil
    begin_scope
    resolve(stmt.nodes)
    end_scope
  end

  def visit_every_stmt(stmt : Statement::Every) : Nil
    resolve(stmt.var)
    resolve(stmt.enumerable)
    resolve(stmt.block)
  end

  def visit_single_expr_stmt(stmt : Statement::SingleExpression) : Nil
    resolve(stmt.expression)
  end

  def visit_if_stmt(stmt : Statement::If) : Nil
    resolve(stmt.condition)
    resolve(stmt.then)
    resolve(stmt.else.not_nil!) unless stmt.else.nil?
  end

  def visit_unless_stmt(stmt : Statement::Unless) : Nil
    resolve(stmt.condition)
    resolve(stmt.then)
    resolve(stmt.else.not_nil!) unless stmt.else.nil?
  end

  def visit_return_stmt(stmt : Statement::Return) : Nil
    if @current_fn == FnType::None
      Logger.report_error("Invalid return", "A 'return' statement can only be used within a method body.", stmt.keyword)
    end
    resolve(stmt.value) unless stmt.value.nil?
  end

  def visit_fn_def_stmt(stmt : Statement::FunctionDef) : Nil
    declare(stmt.identifier)
    define(stmt.identifier)
    resolve_fn(stmt, FnType::Fn)
  end

  def visit_while_stmt(stmt : Statement::While) : Nil
    resolve(stmt.condition)
    resolve(stmt.block)
  end

  def visit_until_stmt(stmt : Statement::Until) : Nil
    resolve(stmt.condition)
    resolve(stmt.block)
  end

  def visit_var_declaration_expr(expr : Expression::VarDeclaration) : Nil
    declare(expr.token)
    resolve(expr.value)
    define(expr.token)
  end

  def visit_var_assignment_expr(expr : Expression::VarAssignment) : Nil
    resolve(expr.value)
    resolve_local(expr, expr.token)
  end

  def visit_property_assignment_expr(expr : Expression::PropertyAssignment) : Nil
    resolve(expr.object)
    resolve(expr.value)
  end

  def visit_type_alias_expr(expr : Expression::TypeAlias) : Nil
    declare(expr.token)
    resolve(expr.value.not_nil!) unless expr.value.nil?
    define(expr.token)
  end

  def visit_fn_call_expr(expr : Expression::FunctionCall) : Nil
    resolve(expr.callee)
    expr.arguments.each { |arg| resolve(arg) }
  end

  def visit_access_expr(expr : Expression::Access) : Nil
    resolve(expr.object)
    resolve_local(expr, expr.token)
  end

  def visit_index_expr(expr : Expression::Index) : Nil
    resolve(expr.key)
    resolve_local(expr, expr.token)
  end

  def visit_compound_assignment_expr(expr : Expression::CompoundAssignment) : Nil
    resolve(expr.value)
    resolve_local(expr, expr.name)
  end

  def visit_binary_op_expr(expr : Expression::BinaryOp) : Nil
    resolve(expr.left)
    resolve(expr.right)
  end

  def visit_unary_op_expr(expr : Expression::UnaryOp) : Nil
    resolve(expr.operand)
  end

  def visit_var_expr(expr : Expression::Var) : Nil
    if !@scopes.empty? && !@scopes.last.nil? && @scopes.last[expr.token.lexeme]? == false
      Logger.report_error("Failed to assign '#{expr.token.lexeme}'", "Cannot read variable in it's own initializer", expr.token)
    end
    resolve_local(expr, expr.token)
  end

  def visit_type_ref_expr(expr : Expression::TypeRef) : Nil
    if !@scopes.empty? && !@scopes.last.nil? && @scopes.last[expr.token.lexeme]? == false
      Logger.report_error("Failed to assign '#{expr.token.lexeme}'", "Cannot read variable in it's own initializer", expr.token)
    end
    resolve_local(expr, expr.token)
  end

  def visit_range_literal_expr(expr : Expression::RangeLiteral) : Nil
    resolve(expr.from)
    resolve(expr.to)
  end

  def visit_table_literal_expr(expr : Expression::TableLiteral) : Nil
    # do nothing
  end

  def visit_vector_literal_expr(expr : Expression::VectorLiteral) : Nil
    # do nothing
  end

  def visit_literal_expr(expr : Expression::Literal) : Nil
    # do nothing
  end

  def visit_break_stmt(stmt : Statement::Break) : Nil
    # do nothing
  end

  def visit_next_stmt(stmt : Statement::Next) : Nil
    # do nothing
  end
end
