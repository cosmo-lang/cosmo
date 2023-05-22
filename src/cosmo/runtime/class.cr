class Cosmo::Class
  @closure : Scope
  getter interpreter : Interpreter
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
    @interpreter.delete_meta("this")
    instance.setup
  end

  def to_s : String
    "<class: 0x#{@definition.object_id.to_s(16)}>"
  end
end

class Cosmo::ClassInstance
  private alias FieldMeta = NamedTuple(
    type: Token,
    constant?: Bool
  )

  @parent : Class
  @args : Array(ValueType)
  @field_meta = {} of String => FieldMeta
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
    # TODO: constant fields
    ctor_method = get_method("construct", include_private: false)
    unless ctor_method.nil?
      @parent.interpreter.set_meta("constructing", name)
      ctor_method.call(@args, return_type_override: "void")
      @parent.interpreter.delete_meta("constructing")
    end

    self
  end

  def define_field(
    name : String,
    value : ValueType,
    token : Token?,
    constant : Bool = false,
    visibility : Visibility = Visibility::Public,
    typedef : Token? = nil
  ) : ClassInstance

    current_meta = @field_meta[name]?
    unless current_meta.nil?
      if current_meta[:constant?]
        Logger.report_error("Attempt to assign to constant property", name, token.not_nil!)
      end
    end

    meta_hash = {} of Symbol => Token | Bool
    meta_hash[:constant?] = constant
    unless typedef.nil?
      meta_hash[:type] = typedef
    else
      unless current_meta.nil?
        typedef = current_meta[:type]
        TypeChecker.assert(typedef.lexeme + "|void", value, typedef)
      end
    end

    @field_meta[name] = FieldMeta.from(meta_hash)
    registry = visibility == Visibility::Public ? @public : visibility == Visibility::Protected ? @protected : @private
    registry["fields"].as(Hash(String, ValueType))[name] = value
    self
  end

  def define_method(name : String, value : Function, token : Token? = nil, visibility : Visibility = Visibility::Public) : ClassInstance
    registry = visibility == Visibility::Public ? @public : visibility == Visibility::Protected ? @protected : @private
    if !token.nil? && registry["methods"].as(Hash(String, Function)).has_key?(name)
      Logger.report_error("Duplicate method definition in '#{name}'", name, token)
    end

    registry["methods"].as(Hash(String, Function))[name] = value
    self
  end

  def get_member(name : String, token : Token? = nil, include_private : Bool = true, include_protected : Bool = false) : ValueType?
    get_method(name, token, include_private, include_protected) || get_field(name, token, include_private, include_protected)
  end

  def get_field(name : String, token : Token? = nil, include_private : Bool = true, include_protected : Bool = false) : ValueType?
    field = @public["fields"][name]?
    if include_private
      field ||= @private["fields"][name]?
    end
    if include_protected
      field ||= @protected["fields"][name]?
    end
    unless token.nil? || include_private || @private["fields"][name]?.nil?
      Logger.report_error("Attempt to access private field", name, token)
    end
    unless token.nil? || include_protected || @protected["methods"][name]?.nil?
      Logger.report_error("Attempt to access protected field outside of class definition", name, token)
    end
    field.as ValueType?
  end

  def get_method(name : String, token : Token? = nil, include_private : Bool = true, include_protected : Bool = false) : Function?
    method = @public["methods"][name]?
    if include_private
      method ||= @private["methods"][name]?
    end
    if include_protected
      method ||= @protected["methods"][name]?
    end
    unless token.nil? || include_private || @private["methods"][name]?.nil?
      Logger.report_error("Attempt to access private method", name, token)
    end
    unless token.nil? || include_protected || @protected["methods"][name]?.nil?
      Logger.report_error("Attempt to access protected method outside of class definition", name, token)
    end
    method.as Function?
  end

  def name
    @parent.name
  end
end
