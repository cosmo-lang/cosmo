require "./spec_helper"

describe Lexer do
  unexpected_float = "Unexpected float: Hex/octal/binary literals must be integers"
  it "throws for unexpected characters" do
    lexer = Lexer.new("@/\\", "test")
    expect_raises(Exception, "[0:2] Unexpected character: @") { lexer.tokenize }
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

    tokens = Lexer.new(lines.join('\n'), "test").tokenize
    eof = tokens.pop
    tokens.empty?.should be_true
  end
  it "lexes floats" do
    tokens = Lexer.new("1234.4321", "test").tokenize
    tokens.first.type.should eq Syntax::Float
    tokens.first.value.should eq 1234.4321
  end
  it "lexes integers" do
    tokens = Lexer.new("1234", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 1234
  end
  it "lexes hex literals" do
    tokens = Lexer.new("0xabc123", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 11256099

    tokens = Lexer.new("0xdE43FA", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 14566394

    tokens = Lexer.new("0x123ABC", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 1194684

    lexer = Lexer.new("0xAE.0", "test")
    expect_raises(Exception, "[1:7] #{unexpected_float}") { lexer.tokenize }
  end
  it "lexes binary literals" do
    tokens = Lexer.new("0b11111", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 31

    tokens = Lexer.new("0b1011011", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 91

    lexer = Lexer.new("0b11.2", "test")
    expect_raises(Exception, "[1:6] #{unexpected_float}") { lexer.tokenize }
  end
  it "lexes octal literals" do
    tokens = Lexer.new("0o31234", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 12956

    tokens = Lexer.new("0o47234", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 20124

    lexer = Lexer.new("0o36.5", "test")
    expect_raises(Exception, "[1:7] #{unexpected_float}") { lexer.tokenize }
  end
  it "lexes booleans" do
    tokens = Lexer.new("true", "test").tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should be_true

    tokens = Lexer.new("false", "test").tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should be_false
  end
  it "lexes none value" do
    tokens = Lexer.new("none", "test").tokenize
    tokens.first.type.should eq Syntax::None
    tokens.first.value.should eq nil
  end
  it "lexes strings" do
    tokens = Lexer.new("\"hello world\"", "test").tokenize
    tokens.first.type.should eq Syntax::String
    tokens.first.value.should eq "hello world"
  end
  it "lexes chars" do
    tokens = Lexer.new("'h'", "test").tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq 'h'

    tokens = Lexer.new("'i'", "test").tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq 'i'

    tokens = Lexer.new("'$'", "test").tokenize
    tokens.first.type.should eq Syntax::Char
    tokens.first.value.should eq '$'
  end
  it "lexes identifiers" do
    tokens = Lexer.new("abcdef", "test").tokenize
    tokens.first.type.should eq Syntax::Identifier
    tokens.first.value.should eq "abcdef"

    tokens = Lexer.new("_this_isValid$", "test").tokenize
    tokens.first.type.should eq Syntax::Identifier
    tokens.first.value.should eq "_this_isValid$"
  end
  it "lexes keywords" do
    tokens = Lexer.new("every if unless in of else fn", "test").tokenize
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
    tokens = Lexer.new("int void string char any type", "test").tokenize
    int, void, string, char, any, type = tokens
    int.type.should eq Syntax::TypeDef
    int.value.should eq "int"
    void.type.should eq Syntax::TypeDef
    void.value.should eq "void"
    string.type.should eq Syntax::TypeDef
    string.value.should eq "string"
    char.type.should eq Syntax::TypeDef
    char.value.should eq "char"
    any.type.should eq Syntax::TypeDef
    any.value.should eq "any"
    type.type.should eq Syntax::TypeDef
    type.value.should eq "type"
  end
  it "lexes other characters" do
    tokens = Lexer.new("$ -> >= & :: .. . # !", "test").tokenize
    this, hyph_arrow, gr_eq, amper, double_colon, dotdot, dot, hashtag, bang = tokens
    this.type.should eq Syntax::This
    this.value.should eq nil
    hyph_arrow.type.should eq Syntax::HyphenArrow
    hyph_arrow.value.should eq nil
    gr_eq.type.should eq Syntax::GreaterEqual
    gr_eq.value.should eq nil
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
    bang.type.should eq Syntax::Bang
    bang.value.should eq nil
  end
end
