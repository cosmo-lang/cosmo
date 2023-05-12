require "../syntax_type"

module Cosmo::Keywords
  KEYWORDS = {
    "true" => Syntax::Boolean,
    "false" => Syntax::Boolean,
    "none" => Syntax::None,
    "fn" => Syntax::Function,
    "if" => Syntax::If,
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

  TYPE_KEYWORDS = {
    "bool" => Syntax::BooleanType,
    "string" => Syntax::StringType,
    "char" => Syntax::CharType,
    "int" => Syntax::IntegerType,
    "float" => Syntax::FloatType,
    "void" => Syntax::VoidType,
    "none" => Syntax::NoneType,
  }

  def self.type?(s)
    TYPE_KEYWORDS.has_key?(s)
  end

  def self.get_type_syntax(s)
    TYPE_KEYWORDS.fetch(s) { raise "Invalid type keyword #{s}" }
  end

  def self.keyword?(s)
    KEYWORDS.has_key?(s)
  end

  def self.get_syntax(s)
    KEYWORDS.fetch(s) { raise "Invalid keyword #{s}" }
  end
end
