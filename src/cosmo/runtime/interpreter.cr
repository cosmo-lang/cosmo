require "../syntax/parser"

class Cosmo::Interpreter
  getter output_ast : Bool = false

  def initialize(@output_ast)
  end

  def interpret(source : String, file_path : String) : LiteralType
    puts Parser.new(source, file_path).parse.to_s
  end
end
