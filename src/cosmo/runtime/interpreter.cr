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
