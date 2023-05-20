require "./spec_helper"
include AST

def assert_var_declaration(
  expr : Expression::Base,
  type : String,
  ident : String,
  constant : Bool = false
) : Expression::Base
  expr.should be_a Expression::VarDeclaration
  declaration = expr.as Expression::VarDeclaration
  declaration.constant?.should eq constant
  declaration.typedef.type.should eq Syntax::TypeDef
  declaration.typedef.value.should eq type
  declaration.typedef.lexeme.should eq type
  declaration.var.should be_a Expression::Var
  declaration.var.token.type.should eq Syntax::Identifier
  declaration.var.token.value.should eq ident
  declaration.var.token.lexeme.should eq ident
  declaration
end

describe Parser do
  describe "parses literals" do
    it "floats" do
      stmts = Parser.new("6.54321", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::FloatLiteral
      literal.should be_a Expression::FloatLiteral
      literal.value.should eq 6.54321
    end
    it "integers" do
      stmts = Parser.new("1234", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::IntLiteral
      literal.should be_a Expression::IntLiteral
      literal.as(Expression::IntLiteral).value.should eq 1234

      stmts = Parser.new("0xABC", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::IntLiteral
      literal.should be_a Expression::IntLiteral
      literal.as(Expression::IntLiteral).value.should eq 2748

      stmts = Parser.new("0b1111", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::IntLiteral
      literal.should be_a Expression::IntLiteral
      literal.value.should eq 15
    end
    it "booleans" do
      stmts = Parser.new("false", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::BooleanLiteral
      literal.should be_a Expression::BooleanLiteral
      literal.value.should be_false

      stmts = Parser.new("true", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::BooleanLiteral
      literal.should be_a Expression::BooleanLiteral
      literal.value.should be_true
    end
    it "none" do
      stmts = Parser.new("none", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::NoneLiteral
      literal.should be_a Expression::NoneLiteral
      literal.value.should eq nil
    end
    it "vectors" do
      stmts = Parser.new("int[] nums = [1, 2, 3]", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      expr.should be_a Expression::VarDeclaration
      declaration = expr.as Expression::VarDeclaration
      declaration.typedef.type.should eq Syntax::TypeDef
      declaration.typedef.value.should eq "int[]"
      declaration.var.should be_a Expression::Var
      declaration.var.token.type.should eq Syntax::Identifier
      declaration.var.token.value.should eq "nums"
      vector = declaration.value.as Expression::VectorLiteral
      vector.should be_a Expression::VectorLiteral

      vector.values.should be_a Array(Expression::Base)
      list = vector.values.as Array(Expression::Base)
      list.should_not be_empty
      one, two, three = list
      one.as(Expression::IntLiteral).value.should eq 1
      two.as(Expression::IntLiteral).value.should eq 2
      three.as(Expression::IntLiteral).value.should eq 3
    end
    it "tables" do
      stmts = Parser.new("any valid = {{yes -> true, no -> false}}", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      expr.should be_a Expression::VarDeclaration
      declaration = expr.as Expression::VarDeclaration
      declaration.typedef.type.should eq Syntax::TypeDef
      declaration.typedef.value.should eq "any"
      declaration.var.should be_a Expression::Var
      declaration.var.token.type.should eq Syntax::Identifier
      declaration.var.token.value.should eq "valid"
      table = declaration.value.as Expression::TableLiteral
      table.should be_a Expression::TableLiteral
      table.hashmap.should_not be_empty
    end
    it "ranges" do
      stmts = Parser.new("1..7", "test", false).parse
      stmts.should_not be_empty
      expr = stmts.first.as(Statement::SingleExpression).expression
      literal = expr.as Expression::RangeLiteral
      literal.should be_a Expression::RangeLiteral
      literal.from.should be_a Expression::IntLiteral
      literal.to.should be_a Expression::IntLiteral
      from = literal.from.as Expression::IntLiteral
      to = literal.to.as Expression::IntLiteral
      from.value.should eq 1
      to.value.should eq 7
    end
  end
  it "parses unary operators" do
    stmts = Parser.new("+-12", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    unary = expr.as Expression::UnaryOp
    unary.should be_a Expression::UnaryOp
    unary.operator.type.should eq Syntax::Plus

    negate = unary.operand.as Expression::UnaryOp
    negate.should be_a Expression::UnaryOp
    negate.operator.type.should eq Syntax::Minus

    literal = negate.operand.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 12

    stmts = Parser.new("++15", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    unary = expr.as Expression::UnaryOp
    unary.should be_a Expression::UnaryOp
    unary.operator.type.should eq Syntax::PlusPlus

    literal = unary.operand.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 15

    stmts = Parser.new("!true", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    unary = expr.as Expression::UnaryOp
    unary.should be_a Expression::UnaryOp
    unary.operator.type.should eq Syntax::Bang

    literal = unary.operand.as Expression::BooleanLiteral
    literal.should be_a Expression::BooleanLiteral
    literal.value.should be_true

    stmts = Parser.new("*something", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    unary = expr.as Expression::UnaryOp
    unary.should be_a Expression::UnaryOp
    unary.operator.type.should eq Syntax::Star

    literal = unary.operand.as Expression::Var
    literal.should be_a Expression::Var
    literal.token.type.should eq Syntax::Identifier
    literal.token.value.should eq "something"
    stmts = Parser.new("#my_vec", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    unary = expr.as Expression::UnaryOp
    unary.should be_a Expression::UnaryOp
    unary.operator.type.should eq Syntax::Hashtag

    literal = unary.operand.as Expression::Var
    literal.should be_a Expression::Var
    literal.token.type.should eq Syntax::Identifier
    literal.token.value.should eq "my_vec"
  end
  it "parses binary operators" do
    stmts = Parser.new("false :& true", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    binary = expr.as Expression::BinaryOp
    binary.should be_a Expression::BinaryOp
    binary.operator.type.should eq Syntax::ColonAmpersand

    left = binary.left.as Expression::BooleanLiteral
    left.should be_a Expression::BooleanLiteral
    left.value.should be_false

    right = binary.right.as Expression::BooleanLiteral
    right.should be_a Expression::BooleanLiteral
    right.value.should be_true

    stmts = Parser.new("10 % 2", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    binary = expr.as Expression::BinaryOp
    binary.should be_a Expression::BinaryOp
    binary.operator.type.should eq Syntax::Percent

    left = binary.left.as(Expression::IntLiteral)
    left.should be_a Expression::IntLiteral
    left.value.should eq 10

    right = binary.right.as(Expression::IntLiteral)
    right.should be_a Expression::IntLiteral
    right.value.should eq 2

    stmts = Parser.new("16.23 <= 46", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    binary = expr.as Expression::BinaryOp
    binary.should be_a Expression::BinaryOp
    binary.operator.type.should eq Syntax::LessEqual

    left = binary.left.as(Expression::FloatLiteral)
    left.should be_a Expression::FloatLiteral
    left.value.should eq 16.23

    right = binary.right.as(Expression::IntLiteral)
    right.should be_a Expression::IntLiteral
    right.value.should eq 46
  end
  it "parses the ternary operator" do
    stmts = Parser.new("false ? \"no\" : \"yes\"", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    ternary = expr.as Expression::TernaryOp
    ternary.should be_a Expression::TernaryOp
    ternary.operator.type.should eq Syntax::Question

    condition = ternary.condition.as Expression::BooleanLiteral
    condition.should be_a Expression::BooleanLiteral
    condition.value.should be_false

    then_expr = ternary.then.as Expression::StringLiteral
    then_expr.should be_a Expression::StringLiteral
    then_expr.value.should eq "no"

    else_expr = ternary.else.as Expression::StringLiteral
    else_expr.should be_a Expression::StringLiteral
    else_expr.value.should eq "yes"
  end
  it "parses variable references" do
    stmts = Parser.new("abc", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    var = expr.as Expression::Var
    var.should be_a Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "abc"

    stmts = Parser.new("_this_isValid$", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    var = expr.as Expression::Var
    var.should be_a Expression::Var
    var.token.type.should eq Syntax::Identifier
    var.token.value.should eq "_this_isValid$"
  end
  it "parses variable assignments" do
    stmts = Parser.new("abc = 1.234", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    assignment = expr.as Expression::VarAssignment
    assignment.var.should be_a Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "abc"
    literal = assignment.value.as Expression::FloatLiteral
    literal.should be_a Expression::FloatLiteral
    literal.value.should eq 1.234

    stmts = Parser.new("_this_isValid$ = false", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    assignment = expr.as Expression::VarAssignment
    assignment.var.should be_a Expression::Var
    assignment.var.token.type.should eq Syntax::Identifier
    assignment.var.token.value.should eq "_this_isValid$"
    literal = assignment.value.as Expression::BooleanLiteral
    literal.should be_a Expression::BooleanLiteral
    literal.value.should be_false
  end
  it "parses variable declarations" do
    stmts = Parser.new("float abc = 1.234", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    expr.should be_a Expression::VarDeclaration
    declaration = expr.as Expression::VarDeclaration
    declaration.typedef.type.should eq Syntax::TypeDef
    declaration.typedef.value.should eq "float"
    declaration.var.should be_a Expression::Var
    declaration.var.token.type.should eq Syntax::Identifier
    declaration.var.token.value.should eq "abc"
    literal = declaration.value.as Expression::FloatLiteral
    literal.should be_a Expression::FloatLiteral
    literal.value.should eq 1.234

    stmts = Parser.new("bool _this_isValid$ = false", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    declaration = expr.as Expression::VarDeclaration
    declaration.typedef.type.should eq Syntax::TypeDef
    declaration.typedef.value.should eq "bool"
    declaration.var.token.type.should eq Syntax::Identifier
    declaration.var.token.value.should eq "_this_isValid$"
    literal = declaration.value.as Expression::BooleanLiteral
    literal.should be_a Expression::BooleanLiteral
    literal.value.should be_false
  end
  it "parses type aliases" do
    stmts = Parser.new("type MyInt = int", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    expr.should be_a Expression::TypeAlias
    type_alias = expr.as Expression::TypeAlias
    type_alias.type_token.type.should eq Syntax::TypeDef
    type_alias.type_token.value.should eq "type"
    type_alias.var.should be_a Expression::Var
    type_alias.var.token.type.should eq Syntax::Identifier
    type_alias.var.token.value.should eq "MyInt"

    type_alias.value.should be_a Expression::TypeRef
    alias_value = type_alias.value.as Expression::TypeRef
    alias_value.name.value.should eq "int"
  end
  it "parses compound assignment" do
    stmts = Parser.new("int a = 5; a += 2", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    declaration = assert_var_declaration(expr, "int", "a")
    literal = declaration.value.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 5

    expr = stmts.last.as(Statement::SingleExpression).expression
    expr.should be_a Expression::CompoundAssignment
    assignment = expr.as Expression::CompoundAssignment
    assignment.name.type.should eq Syntax::Identifier
    assignment.name.value.should eq "a"
    assignment.operator.type.should eq Syntax::PlusEqual
    literal = assignment.value.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 2
  end
  it "parses property assignment" do
    stmts = Parser.new("foo::bar = \"baz\"", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    expr.should be_a Expression::PropertyAssignment
    assignment = expr.as Expression::PropertyAssignment
    assignment.object.should be_a Expression::Access
    access = assignment.object.as Expression::Access
    access.key.should be_a Token
    access.key.lexeme.should eq "bar"
    access.object.should be_a Expression::Var
    access.object.as(Expression::Var).token.lexeme.should eq "foo"
    assignment.value.should be_a Expression::StringLiteral
    assignment.value.as(Expression::StringLiteral).value.should eq "baz"
  end
  it "parses function definitions & calls" do
    lines = [
      "bool fn is_eq(int a, int b) {",
      " a == b",
      "}",
      "is_eq(1, 1)",
    ]
    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    function_def = stmts.first.as Statement::FunctionDef
    function_def.parameters.should_not be_empty
    function_def.parameters.first.typedef.value.should eq "int"
    function_def.parameters.first.identifier.value.should eq "a"
    function_def.parameters.last.typedef.value.should eq "int"
    function_def.parameters.last.identifier.value.should eq "b"
    function_def.identifier.value.should eq "is_eq"
    function_def.body.nodes.should_not be_empty
    function_def.return_typedef.type.should eq Syntax::TypeDef
    function_def.return_typedef.value.should eq "bool"

    expr = function_def.body.nodes.first.as(Statement::SingleExpression).expression
    expr.should be_a Expression::BinaryOp

    expr = stmts.last.as(Statement::SingleExpression).expression
    function_call = expr.as Expression::FunctionCall
    function_call.token.type.should eq Syntax::Identifier
    function_call.token.value.should eq "is_eq"
    arg1, arg2 = function_call.arguments

    arg1.should be_a Expression::IntLiteral
    arg1.as(Expression::IntLiteral).value.should eq 1
    arg2.should be_a Expression::IntLiteral
    arg2.as(Expression::IntLiteral).value.should eq 1

    stmts = Parser.new(lines.last + " == none", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    binary = expr.as Expression::BinaryOp
    function_call = binary.left.as Expression::FunctionCall
    function_call.token.type.should eq Syntax::Identifier
    function_call.token.value.should eq "is_eq"

    binary.operator.type.should eq Syntax::EqualEqual
    binary.right.should be_a Expression::NoneLiteral

    lines = [
      "void fn say_hi() {",
      " puts(\"hi\")",
      "}",
      "say_hi()",
    ]
    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    function_def = stmts.first.as Statement::FunctionDef
    function_def.parameters.empty?.should be_true
    function_def.identifier.value.should eq "say_hi"
    function_def.body.nodes.should_not be_empty
    function_def.return_typedef.type.should eq Syntax::TypeDef
    function_def.return_typedef.value.should eq "void"

    expr = function_def.body.nodes.first.as(Statement::SingleExpression).expression
    expr.should be_a Expression::FunctionCall
    function_call = expr.as Expression::FunctionCall
    function_call.token.type.should eq Syntax::Identifier
    function_call.token.value.should eq "puts"

    arg = function_call.arguments.first
    arg.should be_a Expression::StringLiteral
    arg.as(Expression::StringLiteral).value.should eq "hi"

    expr = stmts.last.as(Statement::SingleExpression).expression
    function_call = expr.as Expression::FunctionCall
    function_call.token.type.should eq Syntax::Identifier
    function_call.token.value.should eq "say_hi"
    function_call.arguments.empty?.should be_true
  end
  it "parses vector indexing" do
    stmts = Parser.new("int[] x = [1, 2]; x[0]", "test", false).parse
    stmts.should_not be_empty
    expr = stmts.last.as(Statement::SingleExpression).expression
    index = expr.as Expression::Index
    index.object.token.type.should eq Syntax::Identifier
    index.object.token.value.should eq "x"

    index.key.should be_a Expression::IntLiteral
    key = index.key.as Expression::IntLiteral
    key.value.should eq 0
  end
  it "parses if/unless statements" do
    lines = [
      "int x = 5",
      "if x == 5 ",
      " puts(\"x is 5\")",
      "else",
      " puts(\"x is not 5\")"
    ]

    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    declaration = assert_var_declaration(expr, "int", "x")
    literal = declaration.value.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 5

    stmts.last.should be_a Statement::If
    if_stmt = stmts.last.as Statement::If
    if_stmt.condition.should be_a Expression::BinaryOp
    if_stmt.then.should be_a Statement::SingleExpression
    _then = if_stmt.then.as Statement::SingleExpression
    _then.expression.should be_a Expression::FunctionCall
    if_stmt.else.should be_a Statement::SingleExpression
    _else = if_stmt.else.as Statement::SingleExpression
    _else.expression.should be_a Expression::FunctionCall

    lines = [
      "string name = \"bob\"",
      "unless name == \"bob\"",
      " puts(\"ur not bob... >:(\")",
      "else",
      " puts(\"it's bob!!!!11 :D\")"
    ]

    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    expr = stmts.first.as(Statement::SingleExpression).expression
    declaration = assert_var_declaration(expr, "string", "name")
    literal = declaration.value.as Expression::StringLiteral
    literal.should be_a Expression::StringLiteral
    literal.value.should eq "bob"

    stmts.last.should be_a Statement::Unless
    unless_stmt = stmts.last.as Statement::Unless
    unless_stmt.condition.should be_a Expression::BinaryOp
    unless_stmt.then.should be_a Statement::SingleExpression
    _then = unless_stmt.then.as Statement::SingleExpression
    _then.expression.should be_a Expression::FunctionCall
    unless_stmt.else.should be_a Statement::SingleExpression
    _else = unless_stmt.else.as Statement::SingleExpression
    _else.expression.should be_a Expression::FunctionCall
  end
  it "parses while/until statements" do
    lines = [
      "while true",
      " puts(\"h\")"
    ]

    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    stmts.first.should be_a Statement::While
    while_stmt = stmts.first.as Statement::While
    while_stmt.condition.should be_a Expression::BooleanLiteral
    while_stmt.condition.as(Expression::BooleanLiteral).value.should eq true
    while_stmt.block.should be_a Statement::SingleExpression
    block = while_stmt.block.as Statement::SingleExpression
    block.expression.should be_a Expression::FunctionCall

    lines = [
      "until false",
      " puts(\"h\")"
    ]

    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty
    stmts.first.should be_a Statement::Until
    until_stmt = stmts.first.as Statement::Until
    until_stmt.condition.should be_a Expression::BooleanLiteral
    until_stmt.condition.as(Expression::BooleanLiteral).value.should eq false
    until_stmt.block.should be_a Statement::SingleExpression
    block = until_stmt.block.as Statement::SingleExpression
    block.expression.should be_a Expression::FunctionCall
  end
  it "parses every statements" do
    lines = [
      "const int[] nums = [1,2,3]",
      "int sum = 0",
      "every int n in nums",
      " sum += n"
    ]

    stmts = Parser.new(lines.join('\n'), "test", false).parse
    stmts.should_not be_empty

    expr = stmts.first.as(Statement::SingleExpression).expression
    declaration = assert_var_declaration(expr, "int[]", "nums", constant: true)
    literal = declaration.value.as Expression::VectorLiteral
    literal.should be_a Expression::VectorLiteral
    literal.values.first.should be_a Expression::IntLiteral

    expr = stmts[1].as(Statement::SingleExpression).expression
    declaration = assert_var_declaration(expr, "int", "sum")
    literal = declaration.value.as Expression::IntLiteral
    literal.should be_a Expression::IntLiteral
    literal.value.should eq 0

    stmts.last.should be_a Statement::Every
    every_stmt = stmts.last.as Statement::Every
    declaration = assert_var_declaration(every_stmt.var, "int", "n", constant: false)
    every_stmt.enumerable.should be_a Expression::Var
    every_stmt.block.should be_a Statement::SingleExpression
    block = every_stmt.block.as Statement::SingleExpression
    block.expression.should be_a Expression::CompoundAssignment
  end
end
