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
    mutable = false,
    visibility : Visibility = Visibility::Private,
    typedef : Token? = nil,
    not_redefining = false
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

      if typedef.nil?
        unless current_meta.nil?
          typedef = current_meta[:type]
          TypeChecker.assert(typedef.lexeme + "|void", value, typedef)
        end
      else
        meta_hash[:type] = typedef
        @field_meta[field_name] = FieldMeta.from(meta_hash)
      end
    end

    if not_redefining
      registry = @public["fields"].has_key?(field_name) ? @public : (@protected["fields"].has_key?(field_name) ? @protected : @private)
    else
      registry = visibility == Visibility::Public ? @public : (visibility == Visibility::Protected ? @protected : @private)
    end

    registry["fields"].as(Hash(String, ValueType))[field_name] = value
    value
  end

  def define_method(method_name : String, value : Function, token : Token? = nil, visibility : Visibility = Visibility::Private) : Function
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
    include_private = true,
    include_protected = false,
    method_required = false,
    field_required = true
  ) : ValueType

    get_method(
      member_name, token,
      include_private,
      include_protected,
      required: method_required
    ) || get_field(
      member_name,
      token,
      include_private,
      include_protected,
      required: field_required
    )
  end

  def get_field(
    field_name : String,
    token : Token? = nil,
    include_private = true,
    include_protected = false,
    required = true
  ) : ValueType

    field : ValueType? = @public["fields"][field_name]?
    meta : FieldMeta? = @field_meta[field_name]?

    if meta.nil? && !token.nil? && required
      Logger.report_error("Field '#{field_name}' does not exist on", name, token)
    end

    if include_private
      field ||= @private["fields"][field_name]?
    end
    if include_protected
      field ||= @protected["fields"][field_name]?
    end

    if !token.nil? && !include_private && @private["fields"].has_key?(field_name)
      Logger.report_error("Attempt to access private field", field_name, token)
    end

    field.as ValueType
  end

  def get_method(
    method_name : String,
    token : Token? = nil,
    include_private = true,
    include_protected = false,
    required = true
  ) : Function?
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
    if method.nil? && !token.nil? && required
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
