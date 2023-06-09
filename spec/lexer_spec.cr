require "./spec_helper"

describe Lexer do
  unexpected_float = "Unexpected float: Hex/octal/binary literals must be integers"
  it "throws for unexpected characters" do
    lexer = Lexer.new("@", "test", false)
    expect_raises(Exception, "Unexpected character: @") { lexer.tokenize }
    lexer = Lexer.new("\\", "test", false)
    expect_raises(Exception, "Unexpected character: \\") { lexer.tokenize }
  end
  it "skips comments & whitespaces" do
    lines = [
      "## single line comment",
      "## another single line foo",
      "#:",
      "this is",
      "a big ol",
      "multiline",
      "comment",
      ":#",
      "\t\n\n",
      "    "
    ]

    tokens = Lexer.new(lines.join('\n'), "test", false).tokenize
    eof = tokens.pop
    tokens.empty?.should be_true
  end
  it "lexes floats" do
    tokens = Lexer.new("1234.4321", "test", false).tokenize
    tokens.first.type.should eq Syntax::Float
    tokens.first.value.should eq 1234.4321
  end
  it "lexes integers" do
    tokens = Lexer.new("1234", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 1234
  end
  it "lexes hex literals" do
    tokens = Lexer.new("0xabc123", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 11256099

    tokens = Lexer.new("0xdE43FA", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 14566394

    tokens = Lexer.new("0x123ABC", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 1194684

    lexer = Lexer.new("0xAE.0", "test", false)
    expect_raises(Exception, "#{unexpected_float}") { lexer.tokenize }
  end
  it "lexes binary literals" do
    tokens = Lexer.new("0b11111", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 31

    tokens = Lexer.new("0b1011011", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 91

    lexer = Lexer.new("0b11.2", "test", false)
    expect_raises(Exception, "#{unexpected_float}") { lexer.tokenize }
  end
  it "lexes octal literals" do
    tokens = Lexer.new("0o31234", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 12956

    tokens = Lexer.new("0o47234", "test", false).tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 20124

    lexer = Lexer.new("0o36.5", "test", false)
    expect_raises(Exception, "#{unexpected_float}") { lexer.tokenize }
  end
  it "lexes booleans" do
    tokens = Lexer.new("true", "test", false).tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should be_true

    tokens = Lexer.new("false", "test", false).tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should be_false
  end
  it "lexes none value" do
    tokens = Lexer.new("none", "test", false).tokenize
    tokens.first.type.should eq Syntax::None
    tokens.first.value.should eq nil
  end
  it "lexes strings" do
    tokens = Lexer.new("\"hello world\"", "test", false).tokenize
    tokens.first.type.should eq Syntax::String
    tokens.first.value.should eq "hello world"
  end
  it "lexes chars" do
    tokens = Lexer.new("'h'", "test", false).tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq 'h'

    tokens = Lexer.new("'i'", "test", false).tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq 'i'

    tokens = Lexer.new("'$'", "test", false).tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq '$'
  end
  it "lexes identifiers" do
    tokens = Lexer.new("abcdef1234", "test", false).tokenize
    tokens.first.type.should eq Syntax::Identifier
    tokens.first.value.should eq "abcdef1234"
    tokens.first.lexeme.should eq "abcdef1234"

    tokens = Lexer.new("_this_isValid$", "test", false).tokenize
    tokens.first.type.should eq Syntax::Identifier
    tokens.first.value.should eq "_this_isValid$"
    tokens.first.lexeme.should eq "_this_isValid$"

    tokens = Lexer.new("is_thi$_valid?", "test", false).tokenize
    tokens.first.type.should eq Syntax::Identifier
    tokens.first.value.should eq "is_thi$_valid?"
    tokens.first.lexeme.should eq "is_thi$_valid?"
  end
  it "lexes keywords" do
    tokens = Lexer.new("every if unless in of else fn", "test", false).tokenize
    every, _if, _unless, _in, _of, _else, fn = tokens
    every.type.should eq Syntax::Every
    every.value.should eq nil
    every.lexeme.should eq "every"
    _if.type.should eq Syntax::If
    _if.value.should eq nil
    _if.lexeme.should eq "if"
    _unless.type.should eq Syntax::Unless
    _unless.value.should eq nil
    _unless.lexeme.should eq "unless"
    _in.type.should eq Syntax::In
    _in.value.should eq nil
    _in.lexeme.should eq "in"
    _of.type.should eq Syntax::Of
    _of.value.should eq nil
    _of.lexeme.should eq "of"
    _else.type.should eq Syntax::Else
    _else.value.should eq nil
    _else.lexeme.should eq "else"
    fn.type.should eq Syntax::Function
    fn.value.should eq nil
    fn.lexeme.should eq "fn"
  end
  it "lexes type keywords" do
    tokens = Lexer.new("int void string bool char any type", "test", false).tokenize
    int, void, string, bool, char, any, type = tokens
    int.type.should eq Syntax::TypeDef
    int.value.should eq "int"
    void.type.should eq Syntax::TypeDef
    void.value.should eq "void"
    string.type.should eq Syntax::TypeDef
    string.value.should eq "string"
    bool.type.should eq Syntax::TypeDef
    bool.value.should eq "bool"
    char.type.should eq Syntax::TypeDef
    char.value.should eq "char"
    any.type.should eq Syntax::TypeDef
    any.value.should eq "any"
    type.type.should eq Syntax::TypeDef
    type.value.should eq "type"
  end
  it "lexes other characters" do
    tokens = Lexer.new("$ -> %= & :: .. . # !=", "test", false).tokenize
    this, hyph_arrow, perc_eq, amper, double_colon, dotdot, dot, hashtag, bang = tokens
    this.type.should eq Syntax::This
    this.value.should eq nil
    hyph_arrow.type.should eq Syntax::HyphenArrow
    hyph_arrow.value.should eq nil
    perc_eq.type.should eq Syntax::PercentEqual
    perc_eq.value.should eq nil
    amper.type.should eq Syntax::Ampersand
    amper.value.should eq nil
    double_colon.type.should eq Syntax::ColonColon
    double_colon.value.should eq nil
    dotdot.type.should eq Syntax::DotDot
    dotdot.value.should eq nil
    dot.type.should eq Syntax::Dot
    dot.value.should eq nil
    hashtag.type.should eq Syntax::Hashtag
    hashtag.value.should eq nil
    bang.type.should eq Syntax::BangEqual
    bang.value.should eq nil
  end
end
