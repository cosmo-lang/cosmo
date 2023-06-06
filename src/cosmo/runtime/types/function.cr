abstract class Cosmo::Callable
  abstract def call(args : Array(ValueType)) : ValueType
  abstract def arity : Range(UInt32, UInt32)
  abstract def intrinsic? : Bool
  abstract def to_s : String

  def expand_args(args : Array(ValueType)) : Array(ValueType)
    grouped_args = [] of ValueType

    args.each do |arg|
      if arg.is_a?(Spread)
        arg.array.each { |v| grouped_args << v.as ValueType }
      else
        grouped_args << arg.as ValueType
      end
    end

    grouped_args
  end
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
      unless param.spread?
        value = @interpreter.evaluate(param.default_value.not_nil!) unless param.default_value.nil?
        @closure.declare(
          param.typedef,
          param.identifier,
          value,
          mutable: param.mutable?
        )
      end
    end

    @non_nullable_params = params.select { |param| !param.default_value.nil? && !param.typedef.lexeme.ends_with?("?") }
  end

  def call(
    args : Array(ValueType),
    return_type_override : String = return_typedef.lexeme,
    class_instance_override : ClassInstance? = @class_instance
  ) : ValueType

    enclosing_return_type = @interpreter.meta["block_return_type"]?
    @interpreter.set_meta("block_return_type", return_type_override)
    scope = Scope.new(@closure)

    enclosing_within_fn = @interpreter.within_fn
    @interpreter.within_fn = true
    @interpreter.start_recursion(@definition.token)

    unless class_instance_override.nil?
      enclosing_this = @interpreter.meta["this"]?
      @interpreter.set_meta("this", class_instance_override)

      scope.declare(
        @interpreter.fake_typedef(class_instance_override.not_nil!.name),
        @interpreter.fake_ident("$"),
        class_instance_override,
        mutable: true
      )
    end

    # assign params
    params = @definition.is_a?(Statement::FunctionDef) ?
      @definition.as(Statement::FunctionDef).parameters
      : @definition.as(Expression::Lambda).parameters

    params.each_with_index do |param, i|
      default_value = param.default_value.nil? ? nil : @interpreter.evaluate(param.default_value.not_nil!)

      if param.spread?
        typedef = param.typedef.dup
        typedef.lexeme += "[]"

        scope.declare(
          typedef,
          param.identifier,
          expand_args(args),
          mutable: param.mutable?
        )
      else
        value = args[i]? || default_value
        if value.is_a?(Spread)
          spread_idx = 0
          value.array.each do |v|
            param = params[i + spread_idx]?
            scope.declare(
              param.typedef,
              param.identifier,
              v,
              mutable: param.mutable?
            ) unless param.nil?
            spread_idx += 1
          end

          break
        else
          scope.declare(
            param.typedef,
            param.identifier,
            value.as ValueType,
            mutable: param.mutable?
          )
        end
      end
    end

    # execute the body
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

    if enclosing_this.nil?
      @interpreter.delete_meta("this")
    else
      @interpreter.set_meta("this", enclosing_this)
    end

    @interpreter.end_recursion
    @interpreter.within_fn = enclosing_within_fn

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

    start = @non_nullable_params.size
    if params.select(&.spread?).empty?
      finish = params.size
    else
      finish = MAX_FN_PARAMS
    end

    start.to_u .. finish.to_u
  end

  def intrinsic? : Bool
    false
  end

  def to_s : String
    "<fn: 0x#{@definition.object_id.to_s(16)}>"
  end
end
