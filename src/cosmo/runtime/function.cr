class Cosmo::Function
  getter scope : Scope
  getter param_nodes : Array(AST::Expression::Parameter)
  getter arity : Range(UInt32, UInt32)
  getter body : AST::Statement::Block

  def initialize(@scope, @param_nodes, @arity, @body)
  end
end
