class Cosmo::Class
  @closure : Scope
  getter interpreter : Interpreter
  getter definition : Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
  end

  def name_token
    @definition.identifier
  end

  def name
    name_token.lexeme
  end

  def construct(args : Array(ValueType)) : ClassInstance
    instance = ClassInstance.new(self, args)
    @interpreter.set_meta("this", instance)
    @interpreter.execute_block(@definition.body, Scope.new(@closure))
    instance.setup
    @interpreter.delete_meta("this")
    instance
  end

  def to_s : String
    "<class: 0x#{@definition.object_id.to_s(16)}>"
  end
end

class Cosmo::ClassInstance
  private alias FieldMeta = NamedTuple(
    type: Token,
    mutable?: Bool
  )

  @constructing = false
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

  def setup : Nil
    ctor_method = get_method("construct", include_private: false)
    unless ctor_method.nil?
      @constructing = true
      ctor_method.call(@args, return_type_override: "void")
      @constructing = false
    end
  end

  def define_field(
    field_name : String,
    value : ValueType,
    token : Token?,
    mutable : Bool = false,
    visibility : Visibility = Visibility::Public,
    typedef : Token? = nil
  ) : ValueType

    current_meta = @field_meta[field_name]?
    unless current_meta.nil?
      unless current_meta[:mutable?] || @constructing
        Logger.report_error("Attempt to assign to an immutable property", field_name, token.not_nil!)
      end
    end

    if @field_meta[field_name]?.nil?
      meta_hash = {} of Symbol => Token | Bool
      meta_hash[:mutable?] = mutable
      unless typedef.nil?
        meta_hash[:type] = typedef
      else
        unless current_meta.nil?
          typedef = current_meta[:type]
          TypeChecker.assert(typedef.lexeme + "|void", value, typedef)
        end
      end

      @field_meta[field_name] = FieldMeta.from(meta_hash)
    end

    registry = visibility == Visibility::Public ? @public : (visibility == Visibility::Protected ? @protected : @private)
    registry["fields"].as(Hash(String, ValueType))[field_name] = value
    value
  end

  def define_method(method_name : String, value : Function, token : Token? = nil, visibility : Visibility = Visibility::Public) : Function
    registry = visibility == Visibility::Public ? @public : (visibility == Visibility::Protected ? @protected : @private)
    if !token.nil? && registry["methods"].has_key?(method_name)
      Logger.report_error("Duplicate method definition in '#{name}'", method_name, token)
    end

    registry["methods"][method_name] = value
    value
  end

  def get_member(
    member_name : String,
    token : Token? = nil,
    include_private : Bool = true,
    include_protected : Bool = false
  ) : ValueType

    get_method(member_name, token, include_private, include_protected) ||
      get_field(member_name, token, include_private, include_protected)
  end

  def get_field(
    field_name : String,
    token : Token? = nil,
    include_private : Bool = true,
    include_protected : Bool = false
  ) : ValueType

    field : ValueType? = @public["fields"][field_name]?
    meta : FieldMeta? = @field_meta[field_name]?
    if include_private
      field ||= @private["fields"][field_name]?
    end
    if include_protected
      field ||= @protected["fields"][field_name]?
    end
    unless token.nil? || include_private || @private["fields"][field_name]?.nil?
      Logger.report_error("Attempt to access private field", field_name, token)
    end
    if meta.nil? && !token.nil?
      Logger.report_error("Field '#{field_name}' does not exist on", name, token)
    end

    field.as ValueType
  end

  def get_method(method_name : String, token : Token? = nil, include_private : Bool = true, include_protected : Bool = false) : Function?
    method : Function? = @public["methods"][method_name]?.as Function?

    if include_private
      method ||= @private["methods"][method_name]?.as Function?
    end
    if include_protected
      method ||= @protected["methods"][method_name]?.as Function?
    end

    unless token.nil? || include_private || @private["methods"][method_name]?.nil?
      Logger.report_error("Attempt to access private method", method_name, token)
    end
    unless token.nil? || include_protected || @protected["methods"][method_name]?.nil?
      Logger.report_error("Attempt to access protected method outside of class definition", method_name, token)
    end
    if method.nil? && !token.nil?
      Logger.report_error("Method '#{method_name}' does not exist on", name, token)
    end

    method
  end

  def name_token
    @parent.name_token
  end

  def name
    @parent.name
  end
end
