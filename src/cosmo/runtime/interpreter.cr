require "../syntax/parser"

class Cosmo::Interpreter
  getter output_ast : Bool = false

  def initialize(@output_ast)
  end

  def interpret(source : String) : LiteralType
  end
end
