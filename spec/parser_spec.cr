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
    block = Parser.new("false & true", "test").parse
    block.nodes.empty?.should eq false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.class.should eq AST::Expression::BinaryOp
    binary.operator.should eq Syntax::Ampersand

    left = binary.left.as(AST::Expression::BooleanLiteral)
    left.class.should eq AST::Expression::BooleanLiteral
    left.value.should eq false

    right = binary.right.as(AST::Expression::BooleanLiteral)
    right.class.should eq AST::Expression::BooleanLiteral
    right.value.should eq true

    block = Parser.new("10 % 2", "test").parse
    block.nodes.empty?.should eq false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.class.should eq AST::Expression::BinaryOp
    binary.operator.should eq Syntax::Percent

    left = binary.left.as(AST::Expression::IntLiteral)
    left.class.should eq AST::Expression::IntLiteral
    left.value.should eq 10

    right = binary.right.as(AST::Expression::IntLiteral)
    right.class.should eq AST::Expression::IntLiteral
    right.value.should eq 2

    block = Parser.new("16.23 <= 46", "test").parse
    block.nodes.empty?.should eq false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.class.should eq AST::Expression::BinaryOp
    binary.operator.should eq Syntax::LessEqual

    left = binary.left.as(AST::Expression::FloatLiteral)
    left.class.should eq AST::Expression::FloatLiteral
    left.value.should eq 16.23

    right = binary.right.as(AST::Expression::IntLiteral)
    right.class.should eq AST::Expression::IntLiteral
    right.value.should eq 46
  end
  it "parses variable references" do
    block = Parser.new("abc", "test").parse
    block.nodes.empty?.should eq false
    var = block.nodes.first.as AST::Expression::Var
    var.class.should eq AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "abc"

    block = Parser.new("_this_isValid$", "test").parse
    block.nodes.empty?.should eq false
    var = block.nodes.first.as AST::Expression::Var
    var.class.should eq AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "_this_isValid$"
  end
  it "parses variable assignments" do
    block = Parser.new("abc = 1.234", "test").parse
    block.nodes.empty?.should eq false
    assignment = block.nodes.first.as AST::Expression::VarAssignment
    assignment.var.class.should eq AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "abc"
    literal = assignment.value.as AST::Expression::FloatLiteral
    literal.class.should eq AST::Expression::FloatLiteral
    literal.value.should eq 1.234

    block = Parser.new("_this_isValid$ = false", "test").parse
    block.nodes.empty?.should eq false
    assignment = block.nodes.first.as AST::Expression::VarAssignment
    assignment.var.class.should eq AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "_this_isValid$"
    literal = assignment.value.as AST::Expression::BooleanLiteral
    literal.class.should eq AST::Expression::BooleanLiteral
    literal.value.should eq false
  end
  it "parses variable declarations" do

  end
end
