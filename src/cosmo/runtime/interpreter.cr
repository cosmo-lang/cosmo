require "../syntax/parser"; include Cosmo::AST
require "./scope"

class Cosmo::Interpreter
  getter scope = Scope.new
  getter output_ast : Bool = false

  def initialize(@output_ast)
  end

  def interpret(source : String, file_path : String) : LiteralType
    parser = Parser.new(source, file_path)
    ast = parser.parse
    walk(ast)
  end

  private def report_error(error_type : String, message : String, token : Token)
    Logger.report_error(error_type, message, token.location.line, token.location.position)
  end

  private def walk(node : Node) : LiteralType
    case node
    when Statement::Block
      return walk(node.single_expression?.not_nil!) unless node.single_expression?.nil?
      node.nodes.each { |expr| walk(expr) }
    when Expression::Var
      @scope.lookup_variable(node.token)
    when Expression::VarDeclaration, Expression::VarAssignment
      value = walk(node.value)
      @scope.set_variable(node.var.token, value)
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
            left + right.to_i
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
            left - right.to_i
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
            left * right.to_i
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
            left / right.to_i
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
            left ** right.to_i
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
            left % right.to_i
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
            left < right.to_i
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
            left <= right.to_i
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
            left > right.to_i
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
            left >= right.to_i
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
end
