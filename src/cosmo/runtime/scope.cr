require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  property parent : Cosmo::Scope?
  property variables = {} of String => Tuple(String, ValueType)

  def initialize(@parent = nil)
  end

  def declare(typedef : Token, identifier : Token, value : ValueType)
    TypeChecker.assert(typedef.value.to_s, value, typedef) unless value == nil
    @variables[identifier.value.to_s] = {typedef.value.to_s, value}
    value
  end

  def assign(identifier : Token, value : ValueType)
    Logger.report_error("Undefined variable", identifier.value.to_s, identifier) unless @variables.has_key?(identifier.value.to_s)
    typedef, old_value = @variables[identifier.value.to_s]
    TypeChecker.assert(typedef, value, identifier)
    @variables[identifier.value.to_s] = {typedef, value}
    value
  end

  def lookup(token : Token) : ValueType
    identifier = token.value
    if @variables.has_key?(identifier)
      typedef, value = @variables[identifier]
      return value unless typedef.nil? && value.nil?
    else
      unless @parent.nil?
        parent = @parent.not_nil!
        value = parent.lookup(token)
        return value
      end
    end
    Logger.report_error("Undefined variable", token.value.to_s, token) if typedef.nil? && value.nil? && @parent.nil?
  end

  def unwrap : Scope
    @parent || self
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@variables}>"
  end
end
