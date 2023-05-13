require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  property parent : Cosmo::Scope?
  getter local_variables = {} of String => Tuple(String, ValueType)

  def initialize(@parent = nil)
  end

  def declare(typedef : Token, identifier : Token, value : ValueType)
    @local_variables[identifier.value.to_s] = {typedef.value.to_s, value}
    TypeChecker.assert(typedef.value.to_s, value, typedef)
    value
  end

  def assign(identifier : Token, value : ValueType)
    Logger.report_error("Undefined variable", identifier.value.to_s, identifier) unless @local_variables.has_key?(identifier.value.to_s)
    typedef, old_value = @local_variables[identifier.value.to_s]
    TypeChecker.assert(typedef, value, identifier)
    @local_variables[identifier.value.to_s] = {typedef, value}
    value
  end

  def lookup(token : Token) : ValueType
    identifier = token.value
    _, value = @local_variables.has_key?(identifier) ? @local_variables[identifier] : {nil, nil}
    Logger.report_error("Undefined variable", token.value.to_s, token) if value.nil? && @parent.nil?
    return unwrap.lookup(token) if value.nil? && !@parent.nil?
    value
  end

  def unwrap
    @parent.not_nil!
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@local_variables}>"
  end
end
