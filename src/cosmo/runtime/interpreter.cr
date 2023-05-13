require "../syntax/parser"; include Cosmo::AST
require "./function"
require "./scope"

class Cosmo::Interpreter
  getter scope = Scope.new
  getter output_ast : Bool = false
  getter file_path : String = ""

  def initialize(@output_ast)
    globals = {
      "puts" => {"fn", PutsIntrinsic.new(@scope, [
        AST::Expression::Parameter.new(
          typedef: Token.new(Syntax::TypeDef, "any", Location.new("intrinsic", 0, 0)),
          identifier: Token.new(Syntax::Identifier, "msg", Location.new("intrinsic", 0, 0))
        )
      ])}
    } of String => Tuple(String, ValueType)

    @scope.set_global(globals)
  end

  def interpret(source : String, @file_path : String) : ValueType
    parser = Parser.new(source, @file_path)
    ast = parser.parse
    puts ast if @output_ast
    walk(ast)
  end

  private def report_error(error_type : String, message : String, token : Token)
    Logger.report_error(error_type, message, token.location.line, token.location.position)
  end

  private def walk(node : Node) : ValueType?
    case node
    when Statement::Block
      return walk(node.single_expression?.not_nil!) unless node.single_expression?.nil?
      node.nodes.each { |expr| walk(expr) }
    when Statement::FunctionDef
      scope = Scope.new(@scope)
      params = node.parameters
      non_nullable_params = params.select { |param| !param.default_value.nil? }
      params.each do |param| # define default values
        unless param.default_value.nil?
          value = walk(param.default_value.not_nil!)
          scope.declare(param.typedef, param.identifier, value)
        end
      end

      arity = non_nullable_params.size.to_u..node.parameters.size.to_u
      fn = Function.new(scope, node.parameters, arity, node.body)

      typedef = Token.new(Syntax::Identifier, "fn", Location.new(file_path, 0, 0))
      @scope.declare(typedef, node.identifier, fn)
      fn
    when Expression::FunctionCall
      fn = @scope.lookup(node.var.token)
      if fn.is_a?(Function) || fn.is_a?(IntrinsicFunction)
        report_error("Expected #{fn.arity} arguments, got", node.arguments.size.to_s, node.var.token) unless fn.arity.includes?(node.arguments.size)
        @scope = fn.scope
        params = fn.param_nodes

        arg_values = [] of ValueType
        non_nullable_params = params.select { |param| !param.default_value.nil? }
        params.each_with_index do |param, i|
          value = walk(node.arguments[i])
          unless value.nil? && non_nullable_params.includes?(param)
            fn.scope.declare(param.typedef, param.identifier, value)
          end
          arg_values << value
        end

        result = fn.intrinsic? ?
          fn.as(IntrinsicFunction).call(*Tuple(ValueType).from(arg_values))
          : walk(fn.as(Function).body)

        @scope = @scope.unwrap
        result
      else
        report_error("Attempt to call", TypeChecker.get_mapped(fn.class), node.var.token)
      end
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
end
