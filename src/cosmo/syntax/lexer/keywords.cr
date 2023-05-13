require "../syntax_type"

module Cosmo::Keywords
  KEYWORDS = {
    "true" => Syntax::Boolean,
    "false" => Syntax::Boolean,
    "none" => Syntax::None,
    "fn" => Syntax::Function,
    "if" => Syntax::If,
    "in" => Syntax::In,
    "of" => Syntax::Of,
    "else" => Syntax::Else,
    "for" => Syntax::For,
    "while" => Syntax::While,
    "break" => Syntax::Break,
    "next" => Syntax::Next,
    "match" => Syntax::Match,
    "global" => Syntax::Global,
    "const" => Syntax::Constant,
    "return" => Syntax::Return
  }

  TYPE_KEYWORDS = ["any", "bool", "string", "char", "int", "float", "void", "none"]

  def self.type?(s)
    TYPE_KEYWORDS.includes?(s)
  end

  def self.keyword?(s)
    KEYWORDS.has_key?(s)
  end

  def self.get_syntax(s)
    KEYWORDS.fetch(s) { raise "Invalid keyword #{s}" }
  end
end
