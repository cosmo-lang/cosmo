require "./class_instance"

class Cosmo::Class
  @closure : Scope
  getter interpreter : Interpreter
  getter definition : Statement::ClassDef

  def initialize(@interpreter, @closure, @definition)
  end

  def name_token
    @definition.identifier
  end

  def name
    name_token.lexeme
  end

  def construct(args : Array(ValueType)) : ClassInstance
    instance = ClassInstance.new(self, args)
    @interpreter.set_meta("this", instance)
    @interpreter.execute_block(@definition.body, Scope.new(@closure))
    instance.setup
    @interpreter.delete_meta("this")
    instance
  end

  def to_s : String
    "<class: 0x#{@definition.object_id.to_s(16)}>"
  end
end
