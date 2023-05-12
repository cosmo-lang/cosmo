require "../syntax/parser"

class Cosmo::Interpreter
  getter output_ast : Bool = false

  def initialize(@output_ast)
  end

  def interpret(source : String, file_path : String) : LiteralType
    Lexer.new(source, file_path).tokenize.each do |token|
      puts token.to_s
    end
  end
end
