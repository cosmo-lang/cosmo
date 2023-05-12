require "./spec_helper"

describe Parser do
  describe "parses literals" do
    it "floats" do
      block = Parser.new("6.54321", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::FloatLiteral
      literal.class.should eq AST::Expression::FloatLiteral
      literal.value.should eq 6.54321
    end
    it "integers" do
      block = Parser.new("1234", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.class.should eq AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 1234

      block = Parser.new("0xABC", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.class.should eq AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 2748

      block = Parser.new("0b1111", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.class.should eq AST::Expression::IntLiteral
      literal.value.should eq 15
    end
    it "booleans" do
      block = Parser.new("false", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::BooleanLiteral
      literal.class.should eq AST::Expression::BooleanLiteral
      literal.value.should eq false

      block = Parser.new("true", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::BooleanLiteral
      literal.class.should eq AST::Expression::BooleanLiteral
      literal.value.should eq true
    end
    it "none" do
      block = Parser.new("none", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first.as AST::Expression::NoneLiteral
      literal.class.should eq AST::Expression::NoneLiteral
      literal.value.should eq nil
    end
  end
  it "parses unary operators" do
    block = Parser.new("+-12", "test").parse
    block.nodes.empty?.should eq false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.class.should eq AST::Expression::UnaryOp
    unary.operator.should eq Syntax::Plus

    negate = unary.operand.as AST::Expression::UnaryOp
    negate.class.should eq AST::Expression::UnaryOp
    negate.operator.should eq Syntax::Minus

    literal = negate.operand.as AST::Expression::IntLiteral
    literal.class.should eq AST::Expression::IntLiteral
    literal.value.should eq 12

    block = Parser.new("!true", "test").parse
    block.nodes.empty?.should eq false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.class.should eq AST::Expression::UnaryOp
    unary.operator.should eq Syntax::Bang

    literal = unary.operand.as AST::Expression::BooleanLiteral
    literal.class.should eq AST::Expression::BooleanLiteral
    literal.value.should eq true

    block = Parser.new("*something", "test").parse
    block.nodes.empty?.should eq false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.class.should eq AST::Expression::UnaryOp
    unary.operator.should eq Syntax::Star

    literal = unary.operand.as AST::Expression::Var
    literal.class.should eq AST::Expression::Var
    literal.token.type.should eq Syntax::Identifier
    literal.token.value.should eq "something"
  end
  it "parses binary operators" do

  end
  it "parses variable references" do

  end
  it "parses variable assignments" do

  end
  it "parses variable declarations" do

  end
end
