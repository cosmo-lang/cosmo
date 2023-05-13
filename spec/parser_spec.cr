require "./spec_helper"

describe Parser do
  describe "parses literals" do
    it "floats" do
      block = Parser.new("6.54321", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::FloatLiteral
      literal.should be_a AST::Expression::FloatLiteral
      literal.value.should eq 6.54321
    end
    it "integers" do
      block = Parser.new("1234", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 1234

      block = Parser.new("0xABC", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 2748

      block = Parser.new("0b1111", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.value.should eq 15
    end
    it "booleans" do
      block = Parser.new("false", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::BooleanLiteral
      literal.should be_a AST::Expression::BooleanLiteral
      literal.value.should be_false

      block = Parser.new("true", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::BooleanLiteral
      literal.should be_a AST::Expression::BooleanLiteral
      literal.value.should be_true
    end
    it "none" do
      block = Parser.new("none", "test").parse
      block.nodes.empty?.should be_false
      literal = block.nodes.first.as AST::Expression::NoneLiteral
      literal.should be_a AST::Expression::NoneLiteral
      literal.value.should eq nil
    end
  end
  it "parses unary operators" do
    block = Parser.new("+-12", "test").parse
    block.nodes.empty?.should be_false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Plus

    negate = unary.operand.as AST::Expression::UnaryOp
    negate.should be_a AST::Expression::UnaryOp
    negate.operator.type.should eq Syntax::Minus

    literal = negate.operand.as AST::Expression::IntLiteral
    literal.should be_a AST::Expression::IntLiteral
    literal.value.should eq 12

    block = Parser.new("!true", "test").parse
    block.nodes.empty?.should be_false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Bang

    literal = unary.operand.as AST::Expression::BooleanLiteral
    literal.should be_a AST::Expression::BooleanLiteral
    literal.value.should be_true

    block = Parser.new("*something", "test").parse
    block.nodes.empty?.should be_false
    unary = block.nodes.first.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Star

    literal = unary.operand.as AST::Expression::Var
    literal.should be_a AST::Expression::Var
    literal.token.type.should eq Syntax::Identifier
    literal.token.value.should eq "something"
  end
  it "parses binary operators" do
    block = Parser.new("false & true", "test").parse
    block.nodes.empty?.should be_false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.should be_a AST::Expression::BinaryOp
    binary.operator.type.should eq Syntax::Ampersand

    left = binary.left.as(AST::Expression::BooleanLiteral)
    left.should be_a AST::Expression::BooleanLiteral
    left.value.should be_false

    right = binary.right.as(AST::Expression::BooleanLiteral)
    right.should be_a AST::Expression::BooleanLiteral
    right.value.should be_true

    block = Parser.new("10 % 2", "test").parse
    block.nodes.empty?.should be_false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.should be_a AST::Expression::BinaryOp
    binary.operator.type.should eq Syntax::Percent

    left = binary.left.as(AST::Expression::IntLiteral)
    left.should be_a AST::Expression::IntLiteral
    left.value.should eq 10

    right = binary.right.as(AST::Expression::IntLiteral)
    right.should be_a AST::Expression::IntLiteral
    right.value.should eq 2

    block = Parser.new("16.23 <= 46", "test").parse
    block.nodes.empty?.should be_false
    binary = block.nodes.first.as AST::Expression::BinaryOp
    binary.should be_a AST::Expression::BinaryOp
    binary.operator.type.should eq Syntax::LessEqual

    left = binary.left.as(AST::Expression::FloatLiteral)
    left.should be_a AST::Expression::FloatLiteral
    left.value.should eq 16.23

    right = binary.right.as(AST::Expression::IntLiteral)
    right.should be_a AST::Expression::IntLiteral
    right.value.should eq 46
  end
  it "parses variable references" do
    block = Parser.new("abc", "test").parse
    block.nodes.empty?.should be_false
    var = block.nodes.first.as AST::Expression::Var
    var.should be_a AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "abc"

    block = Parser.new("_this_isValid$", "test").parse
    block.nodes.empty?.should be_false
    var = block.nodes.first.as AST::Expression::Var
    var.should be_a AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "_this_isValid$"
  end
  it "parses variable assignments" do
    block = Parser.new("abc = 1.234", "test").parse
    block.nodes.empty?.should be_false
    assignment = block.nodes.first.as AST::Expression::VarAssignment
    assignment.var.should be_a AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "abc"
    literal = assignment.value.as AST::Expression::FloatLiteral
    literal.should be_a AST::Expression::FloatLiteral
    literal.value.should eq 1.234

    block = Parser.new("_this_isValid$ = false", "test").parse
    block.nodes.empty?.should be_false
    assignment = block.nodes.first.as AST::Expression::VarAssignment
    assignment.var.should be_a AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "_this_isValid$"
    literal = assignment.value.as AST::Expression::BooleanLiteral
    literal.should be_a AST::Expression::BooleanLiteral
    literal.value.should be_false
  end
  it "parses variable declarations" do
    block = Parser.new("float abc = 1.234", "test").parse
    block.nodes.empty?.should be_false
    block.nodes.first.should be_a AST::Expression::VarDeclaration
    declaration = block.nodes.first.as AST::Expression::VarDeclaration
    declaration.typedef.type.should eq Syntax::TypeDef
    declaration.typedef.value.should eq "float"
    declaration.var.should be_a AST::Expression::Var
    declaration.var.token.type.should eq Syntax::Identifier
    declaration.var.token.value.should eq "abc"
    literal = declaration.value.as AST::Expression::FloatLiteral
    literal.should be_a AST::Expression::FloatLiteral
    literal.value.should eq 1.234

    block = Parser.new("bool _this_isValid$ = false", "test").parse
    block.nodes.empty?.should be_false
    declaration = block.nodes.first.as AST::Expression::VarDeclaration
    declaration.typedef.type.should eq Syntax::TypeDef
    declaration.typedef.value.should eq "bool"
    declaration.var.token.type.should eq Syntax::Identifier
    declaration.var.token.value.should eq "_this_isValid$"
    literal = declaration.value.as AST::Expression::BooleanLiteral
    literal.should be_a AST::Expression::BooleanLiteral
    literal.value.should be_false
  end
  it "parses function definitions & calls" do
    lines = [
      "bool fn is_eq(int a, int b) {",
      " a == b",
      "}",
      "is_eq(1, 1)"
    ]
    block = Parser.new(lines.join('\n'), "test").parse
    block.nodes.empty?.should be_false
    function_def = block.nodes.first.as AST::Statement::FunctionDef
    function_def.parameters.empty?.should be_false
    function_def.parameters.first.typedef.value.should eq "int"
    function_def.parameters.first.identifier.value.should eq "a"
    function_def.parameters.last.typedef.value.should eq "int"
    function_def.parameters.last.identifier.value.should eq "b"
    function_def.identifier.value.should eq "is_eq"
    function_def.body.nodes.empty?.should be_false
    function_def.body.nodes.first.should be_a AST::Expression::BinaryOp
    function_def.return_typedef.type.should eq Syntax::TypeDef
    function_def.return_typedef.value.should eq "bool"

    function_call = block.nodes.last.as AST::Expression::FunctionCall
    function_call.var.token.type.should eq Syntax::Identifier
    function_call.var.token.value.should eq "is_eq"
    arg1, arg2 = function_call.arguments

    arg1.should be_a AST::Expression::IntLiteral
    arg1.as(AST::Expression::IntLiteral).value.should eq 1
    arg2.should be_a AST::Expression::IntLiteral
    arg2.as(AST::Expression::IntLiteral).value.should eq 1
  end
end
