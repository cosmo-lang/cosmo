module Cosmo::AST::Expression
  module Visitor(R)
    abstract def visit_lambda_expr(expr : Lambda) : R
    abstract def visit_this_expr(expr : This) : R
    abstract def visit_is_in_expr(expr : IsIn) : R
    abstract def visit_is_expr(expr : Is) : R
    abstract def visit_type_alias_expr(expr : TypeAlias) : R
    abstract def visit_type_ref_expr(expr : TypeRef) : R
    abstract def visit_fn_call_expr(expr : FunctionCall) : R
    abstract def visit_multiple_assignment_expr(expr : MultipleAssignment) : R
    abstract def visit_property_assignment_expr(expr : PropertyAssignment) : R
    abstract def visit_var_assignment_expr(expr : VarAssignment) : R
    abstract def visit_var_declaration_expr(expr : VarDeclaration) : R
    abstract def visit_var_expr(expr : Var) : R
    abstract def visit_ternary_op_expr(expr : TernaryOp) : R
    abstract def visit_binary_op_expr(expr : BinaryOp) : R
    abstract def visit_unary_op_expr(expr : UnaryOp) : R
    abstract def visit_cast_expr(expr : Cast) : R
    abstract def visit_string_interpolation_expr(expr : StringInterpolation) : R
    abstract def visit_literal_expr(expr : Literal) : R
    abstract def visit_range_literal_expr(expr : RangeLiteral) : R
    abstract def visit_table_literal_expr(expr : TableLiteral) : R
    abstract def visit_vector_literal_expr(expr : VectorLiteral) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end
end

require "./expressions/access"
require "./expressions/index"
require "./expressions/binary_op"
require "./expressions/unary_op"
require "./expressions/ternary_op"
require "./expressions/cast"
require "./expressions/is"
require "./expressions/is_in"
require "./expressions/type_ref"
require "./expressions/type_alias"
require "./expressions/var"
require "./expressions/var_declaration"
require "./expressions/var_assignment"
require "./expressions/multiple_declaration"
require "./expressions/multiple_assignment"
require "./expressions/property_assignment"
require "./expressions/compound_assignment"
require "./expressions/function_call"
require "./expressions/parameter"
require "./expressions/this"
require "./expressions/new"
require "./expressions/literals"
