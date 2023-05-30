abstract class Cosmo::Callable
  abstract def call(args : Array(ValueType)) : ValueType
  abstract def arity : Range(UInt32, UInt32)
  abstract def intrinsic? : Bool
  abstract def to_s : String
end

class Cosmo::Function < Cosmo::Callable
  @interpreter : Interpreter
  @closure : Scope
  @class_instance : ClassInstance?
  @non_nullable_params : Array(Expression::Parameter)
  getter definition : Statement::FunctionDef | Expression::Lambda

  def initialize(@interpreter, @closure, @definition, @class_instance = nil)
    params = @definition.is_a?(Statement::FunctionDef) ?
      @definition.as(Statement::FunctionDef).parameters
      : @definition.as(Expression::Lambda).parameters

    params.each do |param| # initialize params & define default values
      value = @interpreter.evaluate(param.default_value.not_nil!) unless param.default_value.nil?
      @closure.declare(param.typedef, param.identifier, value, mutable: param.mutable?)
    end

    @non_nullable_params = params.select { |param| !param.default_value.nil? && !param.typedef.lexeme.ends_with?("?") }
  end

  def call(
    args : Array(ValueType),
    return_type_override : String? = nil
  ) : ValueType

    return_type_override ||= return_typedef.lexeme
    enclosing_return_type = @interpreter.meta["block_return_type"]?
    @interpreter.set_meta("block_return_type", return_type_override)
    scope = Scope.new(@closure)

    unless @class_instance.nil?
      scope.declare(
        @interpreter.fake_typedef(@class_instance.not_nil!.name),
        @interpreter.fake_ident("$"),
        @class_instance,
        mutable: true
      )
    end

    # assign params
    params = @definition.is_a?(Statement::FunctionDef) ?
      @definition.as(Statement::FunctionDef).parameters
      : @definition.as(Expression::Lambda).parameters

    params.each_with_index do |param, i|
      value = args[i]? || (param.default_value.nil? ? nil : @interpreter.evaluate(param.default_value.not_nil!))
      scope.declare(
        param.typedef,
        param.identifier,
        value.as ValueType,
        mutable: param.mutable?
      )
    end

    result = nil
    begin
      body = @definition.is_a?(Statement::FunctionDef) ?
        @definition.as(Statement::FunctionDef).body
        : @definition.as(Expression::Lambda).body
      result = @interpreter.execute_block(body, scope, is_fn: true)
    rescue returner : HookedExceptions::Return
      result = returner.value unless return_type_override == "void"
    rescue ex : Exception
      raise ex
    end

    if enclosing_return_type.nil?
      @interpreter.delete_meta("block_return_type")
    else
      @interpreter.set_meta("block_return_type", enclosing_return_type)
    end
    result
  end

  def return_typedef
    @definition.is_a?(Statement::FunctionDef) ?
      @definition.as(Statement::FunctionDef).return_typedef
      : @definition.as(Expression::Lambda).return_typedef
  end

  def arity : Range(UInt32, UInt32)
    params = @definition.is_a?(Statement::FunctionDef) ?
      @definition.as(Statement::FunctionDef).parameters
      : @definition.as(Expression::Lambda).parameters

    @non_nullable_params.size.to_u .. params.size.to_u
  end

  def intrinsic? : Bool
    false
  end

  def to_s : String
    "<fn: 0x#{@definition.object_id.to_s(16)}>"
  end
end
