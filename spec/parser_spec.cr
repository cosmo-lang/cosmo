require "./spec_helper"

describe Parser do
  describe "parses literals" do
    it "floats" do
      stmts = Parser.new("6.54321", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::FloatLiteral
      literal.should be_a AST::Expression::FloatLiteral
      literal.value.should eq 6.54321
    end
    it "integers" do
      stmts = Parser.new("1234", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 1234

      stmts = Parser.new("0xABC", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.as(AST::Expression::IntLiteral).value.should eq 2748

      stmts = Parser.new("0b1111", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::IntLiteral
      literal.should be_a AST::Expression::IntLiteral
      literal.value.should eq 15
    end
    it "booleans" do
      stmts = Parser.new("false", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::BooleanLiteral
      literal.should be_a AST::Expression::BooleanLiteral
      literal.value.should be_false

      stmts = Parser.new("true", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::BooleanLiteral
      literal.should be_a AST::Expression::BooleanLiteral
      literal.value.should be_true
    end
    it "none" do
      stmts = Parser.new("none", "test").parse
      stmts.empty?.should be_false
      expr = stmts.first.as(AST::Statement::SingleExpression).expression
      literal = expr.as AST::Expression::NoneLiteral
      literal.should be_a AST::Expression::NoneLiteral
      literal.value.should eq nil
    end
  end
  it "parses unary operators" do
    stmts = Parser.new("+-12", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    unary = expr.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Plus

    negate = unary.operand.as AST::Expression::UnaryOp
    negate.should be_a AST::Expression::UnaryOp
    negate.operator.type.should eq Syntax::Minus

    literal = negate.operand.as AST::Expression::IntLiteral
    literal.should be_a AST::Expression::IntLiteral
    literal.value.should eq 12

    stmts = Parser.new("!true", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    unary = expr.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Bang

    literal = unary.operand.as AST::Expression::BooleanLiteral
    literal.should be_a AST::Expression::BooleanLiteral
    literal.value.should be_true

    stmts = Parser.new("*something", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    unary = expr.as AST::Expression::UnaryOp
    unary.should be_a AST::Expression::UnaryOp
    unary.operator.type.should eq Syntax::Star

    literal = unary.operand.as AST::Expression::Var
    literal.should be_a AST::Expression::Var
    literal.token.type.should eq Syntax::Identifier
    literal.token.value.should eq "something"
  end
  it "parses binary operators" do
    stmts = Parser.new("false & true", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    binary = expr.as AST::Expression::BinaryOp
    binary.should be_a AST::Expression::BinaryOp
    binary.operator.type.should eq Syntax::Ampersand

    left = binary.left.as AST::Expression::BooleanLiteral
    left.should be_a AST::Expression::BooleanLiteral
    left.value.should be_false

    right = binary.right.as AST::Expression::BooleanLiteral
    right.should be_a AST::Expression::BooleanLiteral
    right.value.should be_true

    stmts = Parser.new("10 % 2", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    binary = expr.as AST::Expression::BinaryOp
    binary.should be_a AST::Expression::BinaryOp
    binary.operator.type.should eq Syntax::Percent

    left = binary.left.as(AST::Expression::IntLiteral)
    left.should be_a AST::Expression::IntLiteral
    left.value.should eq 10

    right = binary.right.as(AST::Expression::IntLiteral)
    right.should be_a AST::Expression::IntLiteral
    right.value.should eq 2

    stmts = Parser.new("16.23 <= 46", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    binary = expr.as AST::Expression::BinaryOp
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
    stmts = Parser.new("abc", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    var = expr.as AST::Expression::Var
    var.should be_a AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "abc"

    stmts = Parser.new("_this_isValid$", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    var = expr.as AST::Expression::Var
    var.should be_a AST::Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "_this_isValid$"
  end
  it "parses variable assignments" do
    stmts = Parser.new("abc = 1.234", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    assignment = expr.as AST::Expression::VarAssignment
    assignment.var.should be_a AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "abc"
    literal = assignment.value.as AST::Expression::FloatLiteral
    literal.should be_a AST::Expression::FloatLiteral
    literal.value.should eq 1.234

    stmts = Parser.new("_this_isValid$ = false", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    assignment = expr.as AST::Expression::VarAssignment
    assignment.var.should be_a AST::Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "_this_isValid$"
    literal = assignment.value.as AST::Expression::BooleanLiteral
    literal.should be_a AST::Expression::BooleanLiteral
    literal.value.should be_false
  end
  it "parses variable declarations" do
    stmts = Parser.new("float abc = 1.234", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    expr.should be_a AST::Expression::VarDeclaration
    declaration = expr.as AST::Expression::VarDeclaration
    declaration.typedef.type.should eq Syntax::TypeDef
    declaration.typedef.value.should eq "float"
    declaration.var.should be_a AST::Expression::Var
    declaration.var.token.type.should eq Syntax::Identifier
    declaration.var.token.value.should eq "abc"
    literal = declaration.value.as AST::Expression::FloatLiteral
    literal.should be_a AST::Expression::FloatLiteral
    literal.value.should eq 1.234

    stmts = Parser.new("bool _this_isValid$ = false", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    declaration = expr.as AST::Expression::VarDeclaration
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
      "is_eq(1, 1)",
    ]
    stmts = Parser.new(lines.join('\n'), "test").parse
    stmts.empty?.should be_false
    function_def = stmts.first.as AST::Statement::FunctionDef
    function_def.parameters.empty?.should be_false
    function_def.parameters.first.typedef.value.should eq "int"
    function_def.parameters.first.identifier.value.should eq "a"
    function_def.parameters.last.typedef.value.should eq "int"
    function_def.parameters.last.identifier.value.should eq "b"
    function_def.identifier.value.should eq "is_eq"
    function_def.body.nodes.empty?.should be_false
    function_def.return_typedef.type.should eq Syntax::TypeDef
    function_def.return_typedef.value.should eq "bool"

    expr = function_def.body.nodes.first.as(AST::Statement::SingleExpression).expression
    expr.should be_a AST::Expression::BinaryOp

    expr = stmts.last.as(AST::Statement::SingleExpression).expression
    function_call = expr.as AST::Expression::FunctionCall
    function_call.var.token.type.should eq Syntax::Identifier
    function_call.var.token.value.should eq "is_eq"
    arg1, arg2 = function_call.arguments

    arg1.should be_a AST::Expression::IntLiteral
    arg1.as(AST::Expression::IntLiteral).value.should eq 1
    arg2.should be_a AST::Expression::IntLiteral
    arg2.as(AST::Expression::IntLiteral).value.should eq 1

    stmts = Parser.new(lines.last + " == none", "test").parse
    stmts.empty?.should be_false
    expr = stmts.first.as(AST::Statement::SingleExpression).expression
    binary = expr.as AST::Expression::BinaryOp
    function_call = binary.left.as AST::Expression::FunctionCall
    function_call.var.token.type.should eq Syntax::Identifier
    function_call.var.token.value.should eq "is_eq"

    binary.operator.type.should eq Syntax::EqualEqual
    binary.right.should be_a AST::Expression::NoneLiteral

    lines = [
      "void fn say_hi() {",
      " puts(\"hi\")",
      "}",
      "say_hi()",
    ]
    stmts = Parser.new(lines.join('\n'), "test").parse
    stmts.empty?.should be_false
    function_def = stmts.first.as AST::Statement::FunctionDef
    function_def.parameters.empty?.should be_true
    function_def.identifier.value.should eq "say_hi"
    function_def.body.nodes.empty?.should be_false
    function_def.return_typedef.type.should eq Syntax::TypeDef
    function_def.return_typedef.value.should eq "void"

    expr = function_def.body.nodes.first.as(AST::Statement::SingleExpression).expression
    expr.should be_a AST::Expression::FunctionCall
    function_call = expr.as AST::Expression::FunctionCall
    function_call.var.token.type.should eq Syntax::Identifier
    function_call.var.token.value.should eq "puts"

    arg = function_call.arguments.first
    arg.should be_a AST::Expression::StringLiteral
    arg.as(AST::Expression::StringLiteral).value.should eq "hi"

    expr = stmts.last.as(AST::Statement::SingleExpression).expression
    function_call = expr.as AST::Expression::FunctionCall
    function_call.var.token.type.should eq Syntax::Identifier
    function_call.var.token.value.should eq "say_hi"
    function_call.arguments.empty?.should be_true
  end
end
