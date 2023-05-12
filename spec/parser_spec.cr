require "./spec_helper"

describe Parser do
  describe "parses literals" do
    it "floats" do
      block = Parser.new("6.54321", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::FloatLiteral).should eq true
      literal.as(AST::Expression::FloatLiteral).value.should eq 6.54321
    end
    it "integers" do
      block = Parser.new("1234", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::IntLiteral).should eq true
      literal.as(AST::Expression::IntLiteral).value.should eq 1234

      block = Parser.new("0xABC", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::IntLiteral).should eq true
      literal.as(AST::Expression::IntLiteral).value.should eq 2748

      block = Parser.new("0b1111", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::IntLiteral).should eq true
      literal.as(AST::Expression::IntLiteral).value.should eq 15
    end
    it "booleans" do
      block = Parser.new("false", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::BooleanLiteral).should eq true
      literal.as(AST::Expression::BooleanLiteral).value.should eq false

      block = Parser.new("true", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::BooleanLiteral).should eq true
      literal.as(AST::Expression::BooleanLiteral).value.should eq true
    end
    it "none" do
      block = Parser.new("none", "test").parse
      block.nodes.empty?.should eq false
      literal = block.nodes.first
      literal.is_a?(AST::Expression::Literal).should eq true
      literal.is_a?(AST::Expression::NoneLiteral).should eq true
      literal.as(AST::Expression::NoneLiteral).value.should eq nil
    end
  end
  it "parses unary operators" do

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
