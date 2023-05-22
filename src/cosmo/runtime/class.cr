class Cosmo::Class
  @interpreter : Interpreter
  @closure : Scope
  getter definition : AST::Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
    # TODO: construct() method -> assign public members to a hash
  end

  def construct(args : Array(ValueType)) : Hash(String, ValueType)
    scope = Scope.new(@closure)
    @interpreter.execute_block(@definition.body, scope)

    ctor_method = scope.lookup?("construct")
    if !ctor_method.nil? && ctor_method.is_a?(Function)
      ctor_method.call(args)
    end

    identifier, instance = @interpreter.meta["this"]
    instance.as Hash(String, ValueType)
  end

  def to_s : String
    "<class #0x#{@definition.object_id.to_s(16)}>"
  end
end
