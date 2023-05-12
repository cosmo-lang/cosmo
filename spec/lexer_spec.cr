require "./spec_helper"

describe Lexer do
  it "throws for unexpected characters" do
    lexer = Lexer.new("@/\\", "test")
    expect_raises(Exception, "[1:1] Unexpected character: @") { lexer.tokenize }
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
    err_msg = "Unexpected float: Hex/binary numbers must be integers"
    expect_raises(Exception, "[6:2] #{err_msg}") { lexer.tokenize }
  end
  it "lexes binary literals" do
    tokens = Lexer.new("0b11111", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 31

    tokens = Lexer.new("0b1011011", "test").tokenize
    tokens.first.type.should eq Syntax::Integer
    tokens.first.value.should eq 91

    lexer = Lexer.new("0b11.2", "test")
    err_msg = "Unexpected float: Hex/binary numbers must be integers"
    expect_raises(Exception, "[5:2] #{err_msg}") { lexer.tokenize }
  end
  it "lexes booleans" do
    tokens = Lexer.new("true", "test").tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should eq true

    tokens = Lexer.new("false", "test").tokenize
    tokens.first.type.should eq Syntax::Boolean
    tokens.first.value.should eq false
  end
  it "lexes none value" do
    tokens = Lexer.new("none", "test").tokenize
    tokens.first.type.should eq Syntax::None
    tokens.first.value.should eq nil
  end
  it "lexes strings" do

  end
  it "lexes chars" do

  end
  it "lexes identifiers" do

  end
  it "lexes keywords" do

  end
  it "lexes type keywords" do

  end
  it "lexes other characters" do

  end
end
