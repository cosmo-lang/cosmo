require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  private alias Variable = NamedTuple(
    type: String,
    value: ValueType,
    mutable: Bool,
    visibility: Visibility
  )

  property parent : Cosmo::Scope?
  property variables = {} of String => Variable

  def initialize(@parent = nil)
  end

  def extend(other : Cosmo::Scope) : Cosmo::Scope
    other.variables.each do |name, data|
      @variables[name] = data if data[:visibility] == Visibility::Public
    end
    self
  end

  private def create_variable(
    typedef : Token | String,
    identifier : Token,
    value : V,
    mutable : Bool,
    visibility : Visibility
  ) : ValueType forall V

    casted_value = TypeChecker.as_value_type(value)
    @variables[identifier.lexeme] = {
      type: typedef.is_a?(Token) ? typedef.lexeme : typedef,
      value: casted_value,
      mutable: mutable,
      visibility: visibility
    }

    casted_value
  end

  def declare(
    typedef : Token,
    identifier : Token,
    value : ValueType,
    mutable : Bool = false,
    visibility : Visibility = Visibility::Private
  ) : ValueType

    TypeChecker.assert(typedef.lexeme, value, typedef) unless value.nil?
    create_variable(typedef, identifier, value, mutable, visibility)
  end

  def assign(identifier : Token, value : ValueType, modifying_instance : Bool = false) : ValueType
    if @variables.has_key?(identifier.lexeme)
      var : Variable = @variables[identifier.lexeme]
      unless var[:mutable] || modifying_instance
        Logger.report_error("Attempt to assign to an immutable variable", identifier.lexeme, identifier)
      end

      TypeChecker.assert(var[:type], value, identifier)
      return create_variable(
        var[:type],
        identifier, value,
        mutable: var[:mutable],
        visibility: var[:visibility]
      )
    end

    return @parent.not_nil!.assign(identifier, value) unless @parent.nil?
    Logger.report_error("Attempt to assign to undefined variable", identifier.lexeme, identifier)
  end

  # Returns true if the variable exists and is public, otherwise false
  def public?(ident : String) : Bool
    return false unless @variables.has_key?(ident)
    @variables[ident][:visibility] == Visibility::Public
  end

  def variable_exists?(ident : String) : Bool
    @variables.has_key?(ident) || (@parent.nil? ? false : @parent.not_nil!.variable_exists?(ident))
  end

  def lookup?(ident : String) : ValueType
    if @variables.has_key?(ident)
      @variables[ident][:value]
    else
      unless @parent.nil?
        return @parent.not_nil!.lookup?(ident)
      end
    end
  end

  def lookup(token : Token) : ValueType
    value = lookup?(token.lexeme)
    unless variable_exists?(token.lexeme)
      Logger.report_error("Undefined variable", token.value.to_s, token) if @parent.nil?
    end
    value
  end

  def lookup_at(distance : UInt32, token : Token) : ValueType
    var = ancestor(distance).variables[token.value.to_s]?
    var.value
  end

  private def ancestor(distance : UInt32) : Scope
    scope = self
    distance.times do
      scope = scope.parent || scope
    end
    scope
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{Stringify.hashmap @variables}>"
  end
end
