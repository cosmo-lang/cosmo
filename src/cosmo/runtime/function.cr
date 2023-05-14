abstract class Cosmo::Callable
  abstract def call(args : Array(ValueType)) : ValueType?
  abstract def arity : Range(UInt32, UInt32)
  abstract def intrinsic? : Bool
  abstract def to_s : String
end

class Cosmo::Function < Cosmo::Callable
  @interpreter : Interpreter
  @closure : Scope
  @definition : AST::Statement::FunctionDef
  @non_nullable_params : Array(AST::Expression::Parameter)

  def initialize(@interpreter, @closure, @definition)
    params = @definition.parameters
    @non_nullable_params = params.select { |param| !param.default_value.nil? }
    params.each do |param| # initialize params & define default values
      value = @interpreter.evaluate(param.default_value.as AST::Expression::Base) unless param.default_value.nil?
      @closure.declare(param.typedef, param.identifier, value)
    end
  end

  def call(args : Array(ValueType)) : ValueType?
    scope = Scope.new(@closure)

    # assign params
    @definition.parameters.each_with_index do |param, i|
      scope.declare(param.typedef, param.identifier, args[i])
    end
    @interpreter.execute_block(@definition.body, scope)
  end

  def arity : Range(UInt32, UInt32)
    @non_nullable_params.size.to_u .. @definition.parameters.size.to_u
  end

  def intrinsic? : Bool
    false
  end

  def to_s : String
    "<fn ##{@definition.hash}>"
  end
end
