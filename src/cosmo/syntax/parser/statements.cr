module Cosmo::AST::Statement
  module Visitor(R)
    # abstract def visit_enum_def_stmt(stmt : EnumDef) : R
    abstract def visit_class_def_stmt(stmt : ClassDef) : R
    abstract def visit_case_stmt(stmt : Case) : R
    abstract def visit_every_stmt(stmt : Every) : R
    abstract def visit_while_stmt(stmt : While) : R
    abstract def visit_until_stmt(stmt : Until) : R
    abstract def visit_if_stmt(stmt : If) : R
    abstract def visit_unless_stmt(stmt : Unless) : R
    abstract def visit_try_catch_stmt(stmt : TryCatch) : R
    abstract def visit_return_stmt(stmt : Return) : R
    abstract def visit_break_stmt(stmt : Break) : R
    abstract def visit_next_stmt(stmt : Next) : R
    abstract def visit_throw_stmt(stmt : Throw) : R
    abstract def visit_use_stmt(stmt : Use) : R
    abstract def visit_fn_def_stmt(stmt : FunctionDef) : R
    abstract def visit_single_expr_stmt(stmt : SingleExpression) : R
    abstract def visit_block_stmt(stmt : Block) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end
end

require "./statements/single_expression"
require "./statements/block"
require "./statements/try_catch"
require "./statements/case"
require "./statements/if"
require "./statements/unless"
require "./statements/every"
require "./statements/while"
require "./statements/until"
require "./statements/break"
require "./statements/next"
require "./statements/return"
require "./statements/throw"
require "./statements/use"
require "./statements/function_def"
require "./statements/class_def"
# require "./statements/enum_def"
