abstract class Cosmo::Callable
  abstract def call(args : Array(ValueType)) : ValueType
  abstract def arity : Range(UInt32, UInt32)
  abstract def intrinsic? : Bool
  abstract def to_s : String
end

class Cosmo::Function < Cosmo::Callable
  @interpreter : Interpreter
  @closure : Scope
  @non_nullable_params : Array(Expression::Parameter)
  getter definition : Statement::FunctionDef

  def initialize(@interpreter, @closure, @definition)
    params = @definition.parameters
    @non_nullable_params = params.select { |param| !param.default_value.nil? }
    params.each do |param| # initialize params & define default values
      value = @interpreter.evaluate(param.default_value.as Expression::Base) unless param.default_value.nil?
      @closure.declare(param.typedef, param.identifier, value)
    end
  end

  def call(args : Array(ValueType), return_type_override : String = @definition.return_typedef.value.to_s) : ValueType
    @interpreter.set_meta("block_return_type", return_type_override)
    scope = Scope.new(@closure)

    # assign params
    @definition.parameters.each_with_index do |param, i|
      value = (args[i] || (param.default_value.nil? ? nil : @interpreter.evaluate(param.default_value.not_nil!))).as ValueType
      scope.declare(param.typedef, param.identifier, value, const: param.const?)
    end

    result = nil
    begin
      result = @interpreter.execute_block(@definition.body, scope, is_fn: true)
    rescue returner : HookedExceptions::Return
      result = returner.value
    rescue ex : Exception
      raise ex
    end

    @interpreter.delete_meta("block_return_type")
    result
  end

  def arity : Range(UInt32, UInt32)
    @non_nullable_params.size.to_u .. @definition.parameters.size.to_u
  end

  def intrinsic? : Bool
    false
  end

  def to_s : String
    "<fn: 0x#{@definition.object_id.to_s(16)}>"
  end
end
