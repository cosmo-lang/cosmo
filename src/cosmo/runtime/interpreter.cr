require "../syntax/parser"; include Cosmo::AST
require "./function"
require "./scope"

class Cosmo::Interpreter
  getter scope = Scope.new
  getter output_ast : Bool = false
  getter file_path : String = ""

  def initialize(@output_ast)
    globals = {
      "puts" => {"fn", PutsIntrinsic.new}
    } of String => Tuple(String, ValueType)

    @scope.variables = globals
  end

  def interpret(source : String, @file_path : String) : ValueType
    parser = Parser.new(source, @file_path)
    ast = parser.parse
    puts ast if @output_ast
    walk(ast)
  end

  def walk_block(block : Statement::Block, block_scope : Scope) : ValueType?
    prev_scope = @scope
    begin
      @scope = block_scope
      return_value = walk(block.single_expression?.not_nil!) unless block.single_expression?.nil?
      block.nodes.each { |expr| walk(expr) }
    rescue ex : Exception
      raise ex
    ensure
      @scope = prev_scope
    end
  end

  def walk(node : Node) : ValueType?
    case node
    when Statement::Block
      walk_block(node, Scope.new(@scope))
    when Statement::FunctionDef
      typedef = Token.new(Syntax::TypeDef, "fn", Location.new(@file_path, 0, 0))
      fn = Function.new(self, @scope, node)
      @scope.declare(typedef, node.identifier, fn)
      fn
    when Expression::FunctionCall
      fn = @scope.lookup(node.var.token)
      unless fn.is_a?(Function) || fn.is_a?(IntrinsicFunction)
        report_error("Attempt to call", TypeChecker.get_mapped(fn.class), node.var.token)
      end
      unless fn.arity.includes?(node.arguments.size)
        report_error("Expected #{fn.arity} arguments, got", node.arguments.size.to_s, node.var.token)
      end

      arg_values = node.arguments.map { |arg| walk(arg) }
      fn.call(arg_values)
    when Expression::Var
      @scope.lookup(node.token)
    when Expression::VarDeclaration
      value = walk(node.value)
      @scope.declare(node.typedef, node.var.token, value)
    when Expression::VarAssignment
      value = walk(node.value)
      @scope.assign(node.var.token, value)
    when Expression::UnaryOp
      operand = walk(node.operand)
      case node.operator.type
      when Syntax::Plus
        if operand.is_a?(Float) || operand.is_a?(Int)
          operand.abs
        else
          report_error("Invalid '+' operand type", operand.class.to_s, node.operator)
        end
      when Syntax::Minus
        if operand.is_a?(Float) || operand.is_a?(Int)
          -operand
        else
          report_error("Invalid '-' operand type", operand.class.to_s, node.operator)
        end
      when Syntax::Bang
        !operand
      when Syntax::Star
        raise "'*' unary operator has not yet implemented."
      when Syntax::Hashtag
        raise "'#' unary operator has not yet implemented."
      end
    when Expression::BinaryOp # TODO: better typechecks
      left = walk(node.left)
      right = walk(node.right)
      case node.operator.type
      when Syntax::Plus
        if left.is_a?(Float)
          if right.is_a?(Float)
            left + right
          elsif right.is_a?(Int)
            left + right.to_f
          else
            report_error("Invalid '+' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left + right
          elsif right.is_a?(Float)
            left.to_f + right
          else
            report_error("Invalid '+' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '+' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Minus
        if left.is_a?(Float)
          if right.is_a?(Float)
            left - right
          elsif right.is_a?(Int)
            left - right.to_f
          else
            report_error("Invalid '-' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left - right
          elsif right.is_a?(Float)
            left.to_f - right
          else
            report_error("Invalid '-' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '-' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Star
        if left.is_a?(Float)
          if right.is_a?(Float)
            left * right
          elsif right.is_a?(Int)
            left * right.to_f
          else
            report_error("Invalid '*' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left * right
          elsif right.is_a?(Float)
            left.to_f * right
          else
            report_error("Invalid '*' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '*' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Slash
        if left.is_a?(Float)
          if right.is_a?(Float)
            left / right
          elsif right.is_a?(Int)
            left / right.to_f
          else
            report_error("Invalid '/' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left / right
          elsif right.is_a?(Float)
            left.to_f / right
          else
            report_error("Invalid '/' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '/' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Carat
        if left.is_a?(Float)
          if right.is_a?(Float)
            left ** right
          elsif right.is_a?(Int)
            left ** right.to_f
          else
            report_error("Invalid '^' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left ** right
          elsif right.is_a?(Float)
            left.to_f ** right
          else
            report_error("Invalid '^' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '^' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Percent
        if left.is_a?(Float)
          if right.is_a?(Float)
            left % right
          elsif right.is_a?(Int)
            left % right.to_f
          else
            report_error("Invalid '%' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left % right
          elsif right.is_a?(Float)
            left.to_f % right
          else
            report_error("Invalid '%' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '%' operand type", left.class.to_s, node.operator)
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
            report_error("Invalid '<' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left < right
          elsif right.is_a?(Float)
            left.to_f < right
          else
            report_error("Invalid '<' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '<' operand type", left.class.to_s, node.operator)
        end
      when Syntax::LessEqual
        if left.is_a?(Float)
          if right.is_a?(Float)
            left <= right
          elsif right.is_a?(Int)
            left <= right.to_f
          else
            report_error("Invalid '<=' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left <= right
          elsif right.is_a?(Float)
            left.to_f <= right
          else
            report_error("Invalid '<=' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '<=' operand type", left.class.to_s, node.operator)
        end
      when Syntax::Greater
        if left.is_a?(Float)
          if right.is_a?(Float)
            left > right
          elsif right.is_a?(Int)
            left > right.to_f
          else
            report_error("Invalid '>' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left > right
          elsif right.is_a?(Float)
            left.to_f > right
          else
            report_error("Invalid '>' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '>' operand type", left.class.to_s, node.operator)
        end
      when Syntax::GreaterEqual
        if left.is_a?(Float)
          if right.is_a?(Float)
            left >= right
          elsif right.is_a?(Int)
            left >= right.to_f
          else
            report_error("Invalid '>=' operand type", right.class.to_s, node.operator)
          end
        elsif left.is_a?(Int)
          if right.is_a?(Int)
            left >= right
          elsif right.is_a?(Float)
            left.to_f >= right
          else
            report_error("Invalid '>=' operand type", right.class.to_s, node.operator)
          end
        else
          report_error("Invalid '>=' operand type", left.class.to_s, node.operator)
        end
      end
    when
    Expression::IntLiteral,
    Expression::FloatLiteral,
    Expression::BooleanLiteral,
    Expression::StringLiteral,
    Expression::CharLiteral,
    Expression::NoneLiteral
      node.value
    else
      raise "Unhandled AST node: #{node.to_s}"
    end
  end

  private def report_error(error_type : String, message : String, token : Token)
    Logger.report_error(error_type, message, token.location.line, token.location.position)
  end
end
