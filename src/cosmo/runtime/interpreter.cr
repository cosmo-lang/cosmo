require "../syntax/parser"; include Cosmo::AST

class Cosmo::Interpreter
  getter output_ast : Bool = false

  def initialize(@output_ast)
  end

  def interpret(source : String, file_path : String) : LiteralType
    parser = Parser.new(source, file_path)
    ast = parser.parse
    walk(ast)
  end

  private def walk(node : Node) : LiteralType
    case node
    when Statement::Block
      return walk(node.single_expression?.not_nil!) unless node.single_expression?.nil?
      node.nodes.each { |expr| walk(expr) }
    when Expression::BinaryOp # typechecks
      left = walk(node.left)
      right = walk(node.right)
      case node.operator
      when Syntax::Plus
        left + right
      when Syntax::Minus
        left - right
      when Syntax::Star
        left * right
      when Syntax::Slash
        left / right
      when Syntax::Carat
        left ** right
      when Syntax::Percent
        left % right
      when Syntax::Ampersand
        left && right
      when Syntax::Pipe
        left || right
      when Syntax::Less
        left < right
      when Syntax::LessEqual
        left <= right
      when Syntax::Greater
        left > right
      when Syntax::GreaterEqual
        left >= right
      when Syntax::EqualEqual
        left == right
      when Syntax::BangEqual
        left != right
      end
    when
    Expression::IntLiteral,
    Expression::FloatLiteral,
    Expression::BooleanLiteral,
    Expression::StringLiteral,
    Expression::CharLiteral,
    Expression::NoneLiteral
      walk_literal(node)
    else
      raise "Unhandled AST node: #{node.to_s}"
    end
  end

  private def walk_literal(node : Expression::Literal) : LiteralType
    node.value
  end
end
