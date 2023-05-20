alias CrystalClass = Class
class Cosmo::Class
  @interpreter : Interpreter
  @closure : Scope
  getter definition : AST::Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
    # TODO: create() method -> assign public members to a hash
  end

  def to_s : String
    "<class ##{@definition.hash}>"
  end
end
