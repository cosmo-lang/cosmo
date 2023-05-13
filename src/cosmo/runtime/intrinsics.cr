MAX_INTRINSIC_PARAMS = 255

abstract class Cosmo::IntrinsicFunction
  getter scope : Scope
  getter param_nodes : Array(AST::Expression::Parameter)
  getter arity : Range(UInt32, UInt32)

  def initialize(@scope, @param_nodes, @arity)
  end

  def intrinsic?
    true
  end

  abstract def call(*args : ValueType) : ValueType
end

class Cosmo::PutsIntrinsic < Cosmo::IntrinsicFunction
  def initialize(scope : Scope, param_nodes : Array(AST::Expression::Parameter))
    super scope, param_nodes, 1.to_u..MAX_INTRINSIC_PARAMS.to_u
  end

  def call(*args : ValueType) : Nil
    puts args.map(&.to_s).join('\t')
  end
end
