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

  private def resolve_fn(fn : Statement::FunctionDef | Expression::Lambda, type : FnType) : Nil
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
      if scope.has_key?(name.lexeme)
        # Logger.report_error("Variable already declared in scope", name.lexeme, name)
      end
      scope[name.lexeme] = false
    end
  end

  private def define(name : Token) : Nil
    return if @scopes.empty?
    @scopes.last[name.lexeme] = true unless @scopes.last.nil?
  end

  def visit_block_stmt(stmt : Statement::Block) : Nil
    begin_scope
    resolve(stmt.nodes)
    end_scope
  end

  def visit_try_catch_stmt(stmt : Statement::TryCatch) : Nil
    resolve(stmt.try_block)
    resolve(stmt.caught_exception)
    resolve(stmt.catch_block)
  end

  def visit_every_stmt(stmt : Statement::Every) : Nil
    resolve(stmt.var)
    resolve(stmt.enumerable)
    resolve(stmt.block)
  end

  def visit_single_expr_stmt(stmt : Statement::SingleExpression) : Nil
    resolve(stmt.expression)
  end

  def visit_case_stmt(stmt : Statement::Case) : Nil
    resolve(stmt.value)
    stmt.comparisons.each do |comparison|
      comparison.conditions.each do |condition_expr|
        resolve(condition_expr)
      end
      resolve(comparison.block)
    end
    resolve(stmt.else.not_nil!) unless stmt.else.nil?
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

  def visit_use_stmt(stmt : Statement::Use) : Nil
    ## do nothing
  end

  def visit_throw_stmt(stmt : Statement::Throw) : Nil
    resolve(stmt.err) unless stmt.err.nil?
  end

  def visit_return_stmt(stmt : Statement::Return) : Nil
    if @current_fn == FnType::None
      Logger.report_error("Invalid return", "A 'return' statement can only be used within a method body.", stmt.keyword)
    end
    resolve(stmt.value) unless stmt.value.nil?
  end

  def visit_class_def_stmt(stmt : Statement::ClassDef) : Nil
    declare(stmt.identifier)
    resolve(stmt.superclass.not_nil!) unless stmt.superclass.nil?
    stmt.mixins.each { |mixin| resolve(mixin) }
    resolve(stmt.body)
    define(stmt.identifier)
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

  def visit_is_in_expr(expr : Expression::IsIn) : Nil
    resolve(expr.value)
    resolve(expr.object)
  end

  def visit_lambda_expr(expr : Expression::Lambda) : Nil
    resolve_fn(expr, FnType::Fn)
  end

  def visit_string_interpolation_expr(expr : Expression::StringInterpolation) : Nil
    expr.parts.each do |part|
      resolve(part) unless part.is_a?(String)
    end
  end

  def visit_var_declaration_expr(expr : Expression::VarDeclaration) : Nil
    declare(expr.token)
    resolve(expr.value)
    define(expr.token)
  end

  def visit_var_assignment_expr(expr : Expression::VarAssignment) : Nil
    resolve(expr.value.as Expression::Base) if expr.value.is_a?(Expression::Base)
    resolve_local(expr, expr.token)
  end


  def visit_property_assignment_expr(expr : Expression::PropertyAssignment) : Nil
    resolve(expr.object)
    resolve(expr.value.as Expression::Base) if expr.value.is_a?(Expression::Base)
  end

  def visit_multiple_declaration_expr(expr : Expression::MultipleDeclaration) : Nil
    expr.declarations.each { |declaration| resolve(declaration) }
  end

  def visit_multiple_assignment_expr(expr : Expression::MultipleAssignment) : Nil
    expr.assignments.each { |assignment| resolve(assignment) }
  end

  def visit_cast_expr(expr : Expression::Cast) : Nil
    resolve(expr.type)
    resolve(expr.value)
  end

  def visit_is_expr(expr : Expression::Is) : Nil
    resolve(expr.value)
    resolve(expr.type)
  end

  def visit_type_alias_expr(expr : Expression::TypeAlias) : Nil
    declare(expr.token)
    resolve(expr.value.not_nil!) unless expr.value.nil?
    define(expr.token)
  end

  def visit_new_expr(expr : Expression::New) : Nil
    resolve(expr.operand)
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
    resolve_local(expr, expr.name.token)
  end

  def visit_ternary_op_expr(expr : Expression::TernaryOp) : Nil
    resolve(expr.condition)
    resolve(expr.then)
    resolve(expr.else)
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

  def visit_this_expr(expr : Expression::This) : Nil
    # do nothing
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
