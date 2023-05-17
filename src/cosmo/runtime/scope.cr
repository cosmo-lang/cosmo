require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  private alias Variable = NamedTuple(type: String, value: ValueType, constant: Bool)

  property parent : Cosmo::Scope?
  property variables = {} of String => Variable

  def initialize(@parent = nil)
  end

  private def cast_array(arr : Array(T)) : Array(ValueType) forall T
    arr.map { |e| cast(e) }
  end

  private def cast(value : T) : ValueType forall T
    value.is_a?(Array) ? cast_array(value) : value.as ValueType
  end

  private def create_variable(typedef : Token | String, identifier : Token, value : V, constant : Bool) : ValueType forall V
    casted_value = cast(value)
    @variables[identifier.value.to_s] = {
      type: typedef.is_a?(Token) ? typedef.value.to_s : typedef,
      value: casted_value,
      constant: constant
    }
    casted_value
  end

  def declare_const(typedef : Token, identifier : Token, value : ValueType) : ValueType
    TypeChecker.assert(typedef.value.to_s, value, typedef) unless value.nil?
    create_variable(typedef, identifier, value, constant: true)
  end

  def declare(typedef : Token, identifier : Token, value : ValueType) : ValueType
    TypeChecker.assert(typedef.value.to_s, value, typedef) unless value.nil?
    create_variable(typedef, identifier, value, constant: false)
  end

  def assign(identifier : Token, value : ValueType) : ValueType
    if @variables.has_key?(identifier.value.to_s)
      info = @variables[identifier.value.to_s]
      if info[:constant]
        Logger.report_error("Attempt to assign to constant variable", identifier.value.to_s, identifier)
      end
      TypeChecker.assert(info[:type], value, identifier)
      return create_variable(info[:type], identifier, value, false)
    end

    return @parent.not_nil!.assign(identifier, value) unless @parent.nil?
    Logger.report_error("Attempt to assign to undefined variable", identifier.value.to_s, identifier)
  end

  def lookup?(token : Token) : ValueType
    identifier = token.value
    if @variables.has_key?(identifier)
      var = @variables[identifier]
      typedef = var[:type]
      return var[:value]
    else
      unless @parent.nil?
        parent = @parent.not_nil!
        value = parent.lookup(token)
        return value
      end
    end
    nil
  end

  def lookup(token : Token) : ValueType
    value = lookup?(token)
    if value.nil?
      Logger.report_error("Undefined variable", token.value.to_s, token) if value.nil? && @parent.nil?
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
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@variables}>"
  end
end
