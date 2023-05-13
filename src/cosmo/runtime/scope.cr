require_relative "../code_analysis/syntax/syntax"
require_relative "../logger"

class Scope
  property parent : Scope?
  getter local_variables = {} of String => LiteralType

  def add_variable(identifier : String, value : LiteralType)
    @local_variables[identifier] = value
  end

  def lookup_variable(identifier : String, token : Token) : LiteralType
    value = @local_variables.has_key?(identifier) ? @local_variables[identifier] : nil
    Logger.report_error("Undefined variable", token.value, token.position, token.line) if value.nil? && @parent.nil?
    @parent.lookup_variable(identifier, token) if value.nil? && !@parent.nil?
  end

  def unwrap
    @parent
  end

  def to_s
    "Scope<#{@parent ? "parent: " + @parent.to_s + ", " : ""}#{@local_variables}>"
  end
end
