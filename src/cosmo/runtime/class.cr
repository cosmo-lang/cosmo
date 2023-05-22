class Cosmo::Class
  @interpreter : Interpreter
  @closure : Scope
  getter definition : Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
  end

  def name
    @definition.identifier.lexeme
  end

  def construct(args : Array(ValueType)) : ClassInstance
    instance = ClassInstance.new(self, args)
    @interpreter.set_meta("this", instance)
    @interpreter.execute_block(@definition.body, Scope.new(@closure))
    @interpreter.set_meta("this", nil)
    instance.setup
  end

  def to_s : String
    "<class: 0x#{@definition.object_id.to_s(16)}>"
  end
end

class Cosmo::ClassInstance
  @parent : Class
  @args : Array(ValueType)
  @field_types = {} of String => Token
  @public : Hash(String, Hash(String, Cosmo::Function) | Hash(String, Cosmo::ValueType)) = {
    "fields" => {} of String => ValueType,
    "methods" => {} of String => Function
  }
  @private : Hash(String, Hash(String, Cosmo::Function) | Hash(String, Cosmo::ValueType)) = {
    "fields" => {} of String => ValueType,
    "methods" => {} of String => Function
  }
  @protected : Hash(String, Hash(String, Cosmo::Function) | Hash(String, Cosmo::ValueType)) = {
    "fields" => {} of String => ValueType,
    "methods" => {} of String => Function
  }

  def initialize(@parent, @args)
  end

  def setup : ClassInstance
    ctor_method = get_method("construct", include_private: false)
    # TODO: assign a meta property to allow assignment to constant fields in constructor
    unless ctor_method.nil?
      ctor_method.call(@args, return_type_override: "void")
    end

    self
  end

  def define_field(name : String, value : ValueType, public : Bool = true, _protected : Bool = false, typedef : Token? = nil) : ClassInstance
    unless typedef.nil?
      @field_types[name] = typedef
    else
      typedef = @field_types[name]
      TypeChecker.assert(typedef.lexeme + "|void", value, typedef)
    end
    registry = public ? @public : _protected ? @protected : @private
    registry["fields"].as(Hash(String, ValueType))[name] = value
    self
  end

  def define_method(name : String, value : Function, public : Bool = true, _protected : Bool = false) : ClassInstance
    registry = public ? @public : _protected ? @protected : @private
    registry["methods"].as(Hash(String, Function))[name] = value
    self
  end

  def get_member(name : String, include_private : Bool = true, include_protected : Bool = false) : ValueType?
    get_method(name, include_private, include_protected) || get_field(name, include_private, include_protected)
  end

  def get_field(name : String, include_private : Bool = true, include_protected : Bool = false) : ValueType?
    field = @public["fields"][name]?
    if include_private
      field ||= @private["fields"][name]?
    end
    if include_protected
      field ||= @protected["fields"][name]?
    end
    field.as ValueType?
  end

  def get_method(name : String, include_private : Bool = true, include_protected : Bool = false) : Function?
    method = @public["methods"][name]?
    if include_private
      method ||= @private["methods"][name]?
    end
    if include_protected
      method ||= @protected["methods"][name]?
    end
    method.as Function?
  end

  def name
    @parent.name
  end
end
