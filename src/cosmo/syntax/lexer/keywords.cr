require "../syntax_type"

module Cosmo::Keywords
  KEYWORDS = {
    "and" => Syntax::And,
    "or" => Syntax::Or,
    "not" => Syntax::Not,
    "true" => Syntax::BooleanLiteral,
    "false" => Syntax::BooleanLiteral,
    "none" => Syntax::NoneLiteral,
    "fn" => Syntax::Function,
    "if" => Syntax::If,
    "unless" => Syntax::Unless,
    "in" => Syntax::In,
    "of" => Syntax::Of,
    "is" => Syntax::Is,
    "as" => Syntax::As,
    "else" => Syntax::Else,
    "every" => Syntax::Every,
    "while" => Syntax::While,
    "until" => Syntax::Until,
    "break" => Syntax::Break,
    "next" => Syntax::Next,
    "use" => Syntax::Use,
    "from" => Syntax::From,
    "case" => Syntax::Case,
    "when" => Syntax::When,
    "mut" => Syntax::Mut,
    "return" => Syntax::Return,
    "throw" => Syntax::Throw,
    "try" => Syntax::Try,
    "catch" => Syntax::Catch,
    "finally" => Syntax::Finally,
    "class" => Syntax::Class,
    "mixin" => Syntax::Mixin,
    "new" => Syntax::New,
    "enum" => Syntax::Enum
  }

  # These cannot be any of the keywords above
  TYPE_KEYWORDS = {
    "any" => Syntax::AnyType,
    "bool" => Syntax::BoolType,
    "string" => Syntax::StringType,
    "char" => Syntax::CharType,
    "int" => Syntax::IntType,
    "uint" => Syntax::UIntType,
    "bigint" => Syntax::BigIntType,
    "float" => Syntax::FloatType,
    "void" => Syntax::VoidType
  }

  # Returns whether or not `s` is a class vibility keyword
  def self.class_visibility?(s : String)
    ["protected", "static"].includes?(s)
  end

  # Returns whether or not `s` is a type keyword
  def self.type?(s : String)
    TYPE_KEYWORDS.has_key?(s)
  end

  # Returns whether or not `s` is a regular keyword
  def self.keyword?(s : String)
    KEYWORDS.has_key?(s)
  end

  # Returns the syntax type of `s` if it is a regular keyword
  def self.get_syntax(s : String) : Syntax
    KEYWORDS.fetch(s) { raise "Invalid keyword #{s}" }
  end

  # Returns the syntax type of `s` if it is a regular keyword
  def self.get_type_syntax(s : String) : Syntax
    TYPE_KEYWORDS.fetch(s) { raise "Invalid type #{s}" }
  end
end
