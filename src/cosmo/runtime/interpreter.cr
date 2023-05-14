require "../syntax/parser"; include Cosmo::AST
require "./function"
require "./scope"

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
  @scope : Scope
  @locals = {} of Expression::Base => UInt32
  @meta = {} of String => String

  private def declare_intrinsic(ident : String, value : ValueType)
    location = Location.new("intrinsic", 0, 0)
    ident_token = Token.new(Syntax::Identifier, ident, location)
    typedef_token = Token.new(Syntax::TypeDef, "fn", location)
    @globals.declare(typedef_token, ident_token, value)
  end

  def initialize(@output_ast)
    @scope = @globals
    declare_intrinsic("puts", PutsIntrinsic.new)
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

  def execute_block(block : Statement::Block, block_scope : Scope) : ValueType
    prev_scope = @scope
    begin # TODO: typecheck return types
      @scope = block_scope
      unless block.nodes.empty?
        return_node = block.nodes.find { |node| node.is_a?(Statement::Return) } || block.nodes.last
        body_nodes = block.nodes[0..-2]
        body_nodes.each { |expr| execute(expr.as Statement::Base) }
        return_value = execute(return_node.as Statement::Base) unless return_node.nil?
      end

      return_type = @meta["block_return_type"] || "void"
      token = return_node.nil? ? Token.new(Syntax::None, nil, Location.new("", 0, 0)) : return_node.token
      TypeChecker.assert(return_type, return_value, token)
      return_value
    rescue ex : Exception
      raise ex
    ensure
      @scope = prev_scope
    end
  end

  def visit_single_expr_stmt(stmt : Statement::SingleExpression) : ValueType
    evaluate(stmt.expression)
  end

  def visit_block_stmt(stmt : Statement::Block) : ValueType
    execute_block(stmt, Scope.new(@scope))
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
      report_error("Attempt to call", TypeChecker.get_mapped(fn.class), expr.var.token)
    end
    unless fn.arity.includes?(expr.arguments.size)
      report_error("Expected #{fn.arity} arguments, got", expr.arguments.size.to_s, expr.var.token)
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
    var = @scope.lookup(expr.name)
    value = evaluate(expr.value.as Expression::Base)

    case expr.operator.type
    when Syntax::PlusEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var + value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var + value.to_f)
        else
          report_error("Invalid '+' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var + value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f + value)
        else
          report_error("Invalid '+' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '+' operand type", var.class.to_s, expr.operator)
      end
    when Syntax::MinusEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var + value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var + value.to_f)
        else
          report_error("Invalid '+' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var + value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f + value)
        else
          report_error("Invalid '+' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '+' operand type", var.class.to_s, expr.operator)
      end
    when Syntax::StarEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var * value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var * value.to_f)
        else
          report_error("Invalid '*' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var * value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f * value)
        else
          report_error("Invalid '*' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '*' operand type", var.class.to_s, expr.operator)
      end
    when Syntax::SlashEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var / value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var / value.to_f)
        else
          report_error("Invalid '/' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var / value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f / value)
        else
          report_error("Invalid '/' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '/' operand type", var.class.to_s, expr.operator)
      end
    when Syntax::PercentEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var % value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var % value.to_f)
        else
          report_error("Invalid '%' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var % value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f % value)
        else
          report_error("Invalid '%' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '%' operand type", var.class.to_s, expr.operator)
      end
    when Syntax::CaratEqual
      if var.is_a?(Float)
        if value.is_a?(Float)
          @scope.assign(expr.name, var ** value)
        elsif value.is_a?(Int)
          @scope.assign(expr.name, var ** value.to_f)
        else
          report_error("Invalid '^' operand type", value.class.to_s, expr.operator)
        end
      elsif var.is_a?(Int)
        if value.is_a?(Int)
          @scope.assign(expr.name, var ** value)
        elsif value.is_a?(Float)
          @scope.assign(expr.name, var.to_f ** value)
        else
          report_error("Invalid '^' operand type", value.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '^' operand type", var.class.to_s, expr.operator)
      end
    end
  end

  def visit_unary_op_expr(expr : Expression::UnaryOp) : ValueType
    operand = evaluate(expr.operand.as Expression::Base)
    case expr.operator.type
    when Syntax::Plus
      if operand.is_a?(Float) || operand.is_a?(Int)
        operand.abs
      else
        report_error("Invalid '+' operand type", operand.class.to_s, expr.operator)
      end
    when Syntax::Minus
      if operand.is_a?(Float) || operand.is_a?(Int)
        -operand
      else
        report_error("Invalid '-' operand type", operand.class.to_s, expr.operator)
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
    case expr.operator.type # TODO: better typechecking
    when Syntax::Plus
      if left.is_a?(Float)
        if right.is_a?(Float)
          left + right
        elsif right.is_a?(Int)
          left + right.to_f
        else
          report_error("Invalid '+' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left + right
        elsif right.is_a?(Float)
          left.to_f + right
        else
          report_error("Invalid '+' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '+' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Minus
      if left.is_a?(Float)
        if right.is_a?(Float)
          left - right
        elsif right.is_a?(Int)
          left - right.to_f
        else
          report_error("Invalid '-' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left - right
        elsif right.is_a?(Float)
          left.to_f - right
        else
          report_error("Invalid '-' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '-' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Star
      if left.is_a?(Float)
        if right.is_a?(Float)
          left * right
        elsif right.is_a?(Int)
          left * right.to_f
        else
          report_error("Invalid '*' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left * right
        elsif right.is_a?(Float)
          left.to_f * right
        else
          report_error("Invalid '*' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '*' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Slash
      if left.is_a?(Float)
        if right.is_a?(Float)
          left / right
        elsif right.is_a?(Int)
          left / right.to_f
        else
          report_error("Invalid '/' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left / right
        elsif right.is_a?(Float)
          left.to_f / right
        else
          report_error("Invalid '/' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '/' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Carat
      if left.is_a?(Float)
        if right.is_a?(Float)
          left ** right
        elsif right.is_a?(Int)
          left ** right.to_f
        else
          report_error("Invalid '^' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left ** right
        elsif right.is_a?(Float)
          left.to_f ** right
        else
          report_error("Invalid '^' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '^' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Percent
      if left.is_a?(Float)
        if right.is_a?(Float)
          left % right
        elsif right.is_a?(Int)
          left % right.to_f
        else
          report_error("Invalid '%' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left % right
        elsif right.is_a?(Float)
          left.to_f % right
        else
          report_error("Invalid '%' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '%' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Ampersand
      left && right
    when Syntax::Pipe
      left || right
    when Syntax::EqualEqual
      left == right
    when Syntax::BangEqual
      left != right
    when Syntax::Less
      if left.is_a?(Float)
        if right.is_a?(Float)
          left < right
        elsif right.is_a?(Int)
          left < right.to_f
        else
          report_error("Invalid '<' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left < right
        elsif right.is_a?(Float)
          left.to_f < right
        else
          report_error("Invalid '<' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '<' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::LessEqual
      if left.is_a?(Float)
        if right.is_a?(Float)
          left <= right
        elsif right.is_a?(Int)
          left <= right.to_f
        else
          report_error("Invalid '<=' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left <= right
        elsif right.is_a?(Float)
          left.to_f <= right
        else
          report_error("Invalid '<=' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '<=' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::Greater
      if left.is_a?(Float)
        if right.is_a?(Float)
          left > right
        elsif right.is_a?(Int)
          left > right.to_f
        else
          report_error("Invalid '>' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left > right
        elsif right.is_a?(Float)
          left.to_f > right
        else
          report_error("Invalid '>' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '>' operand type", left.class.to_s, expr.operator)
      end
    when Syntax::GreaterEqual
      if left.is_a?(Float)
        if right.is_a?(Float)
          left >= right
        elsif right.is_a?(Int)
          left >= right.to_f
        else
          report_error("Invalid '>=' operand type", right.class.to_s, expr.operator)
        end
      elsif left.is_a?(Int)
        if right.is_a?(Int)
          left >= right
        elsif right.is_a?(Float)
          left.to_f >= right
        else
          report_error("Invalid '>=' operand type", right.class.to_s, expr.operator)
        end
      else
        report_error("Invalid '>=' operand type", left.class.to_s, expr.operator)
      end
    end
  end

  def visit_literal_expr(expr : Expression::Literal) : ValueType
    expr.value
  end

  def report_error(error_type : String, message : String, token : Token)
    Logger.report_error(error_type, message, token.location.line, token.location.position)
  end
end
