require "../syntax_type"

module Cosmo::Keywords
  KEYWORDS = {
    "and" => Syntax::And,
    "or" => Syntax::Or,
    "not" => Syntax::Not,
    "true" => Syntax::Boolean,
    "false" => Syntax::Boolean,
    "none" => Syntax::None,
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
  TYPE_KEYWORDS = ["type", "any", "bool", "string", "char", "int", "uint", "bigint", "float", "void", "Function"]
  CLASS_VISIBILITY_KEYWORDS = ["protected", "static"]

  # Returns whether or not `s` is a class vibility keyword
  def self.class_visibility?(s : String)
    CLASS_VISIBILITY_KEYWORDS.includes?(s)
  end

  # Returns whether or not `s` is a type keyword
  def self.type?(s : String)
    TYPE_KEYWORDS.includes?(s)
  end

  # Returns whether or not `s` is a regular keyword
  def self.keyword?(s : String)
    KEYWORDS.has_key?(s)
  end

  # Returns the syntax type of `s` if it is a regular keyword
  def self.get_syntax(s : String) : Syntax
    KEYWORDS.fetch(s) { raise "Invalid keyword #{s}" }
  end
end
