class Cosmo::Class
  @interpreter : Interpreter
  @closure : Scope
  getter definition : AST::Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
    # TODO: construct() method -> assign public members to a hash
  end

  def construct()

  end

  def to_s : String
    "<class #0x#{@definition.object_id.to_s(16)}>"
  end
end
