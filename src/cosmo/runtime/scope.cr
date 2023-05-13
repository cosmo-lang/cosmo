require "../syntax/lexer/token"
require "../logger"

class Cosmo::Scope
  property parent : Cosmo::Scope?
  getter local_variables = {} of String => LiteralType

  def set_variable(token : Token, value : LiteralType)
    @local_variables[token.value.to_s] = value
  end

  def lookup_variable(token : Token) : LiteralType
    identifier = token.value
    value = @local_variables.has_key?(identifier) ? @local_variables[identifier] : nil
    Logger.report_error("Undefined variable", token.value.to_s, token.location.position, token.location.line) if value.nil? && @parent.nil?
    return unwrap.lookup_variable(token) if value.nil? && !@parent.nil?
    value
  end

  def unwrap
    @parent.not_nil!
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@local_variables}>"
  end
end
