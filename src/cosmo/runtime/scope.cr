require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  property parent : Cosmo::Scope?
  property variables = {} of String => NamedTuple(type: String, value: ValueType)

  def initialize(@parent = nil)
  end

  def declare(typedef : Token, identifier : Token, value : ValueType) : ValueType
    TypeChecker.assert(typedef.value.to_s, value, typedef) unless value.nil?
    @variables[identifier.value.to_s] = {
      type: typedef.value.to_s,
      value: value
    }
    value
  end

  def assign(identifier : Token, value : ValueType) : ValueType
    if @variables.has_key?(identifier.value.to_s)
      var = @variables[identifier.value.to_s]
      TypeChecker.assert(var[:type], value, identifier)
      @variables[identifier.value.to_s] = {
        type: var[:type],
        value: value
      }
      return value
    end

    return @parent.not_nil!.assign(identifier, value) unless @parent.nil?
    Logger.report_error("Undefined variable", identifier.value.to_s, identifier)
  end

  def lookup(token : Token) : ValueType
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
    Logger.report_error("Undefined variable", token.value.to_s, token) if typedef.nil? && value.nil? && @parent.nil?
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
