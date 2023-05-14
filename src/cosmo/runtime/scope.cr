require "../syntax/lexer/token"
require "./typechecker"

class Cosmo::Scope
  property parent : Cosmo::Scope?
  getter local_variables = {} of String => Tuple(String, ValueType)

  def initialize(@parent = nil)
  end

  def get_locals
    @local_variables
  end

  def set_global(variables : Hash(String, Tuple(String, ValueType)))
    @local_variables = variables
  end

  def declare(typedef : Token, identifier : Token, value : ValueType)
    TypeChecker.assert(typedef.value.to_s, value, typedef) unless value == nil
    @local_variables[identifier.value.to_s] = {typedef.value.to_s, value}
    value
  end

  def assign(identifier : Token, value : ValueType)
    Logger.report_error("Undefined variable", identifier.value.to_s, identifier) unless get_locals.has_key?(identifier.value.to_s)
    typedef, old_value = get_locals[identifier.value.to_s]
    TypeChecker.assert(typedef, value, identifier)
    @local_variables[identifier.value.to_s] = {typedef, value}
    value
  end

  def lookup(token : Token) : ValueType
    identifier = token.value
    if get_locals.has_key?(identifier)
      typedef, value = get_locals[identifier]
    else
      unless @parent.nil?
        parent = @parent.not_nil!
        typedef, value = parent.get_locals[identifier] if parent.get_locals.has_key?(identifier)
      end
    end
    # puts typedef, value, get_locals
    Logger.report_error("Undefined variable", token.value.to_s, token) if typedef.nil? && value.nil? && @parent.nil?
    value
  end

  def unwrap : Scope
    @parent || self
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@local_variables}>"
  end
end
