require "./class_instance"

class Cosmo::Class
  @closure : Scope
  getter interpreter : Interpreter
  getter definition : Statement::ClassDef
  getter superclass : Class?

  def initialize(@interpreter, @closure, @definition, @superclass)
  end

  def name_token
    @definition.identifier
  end

  def name
    name_token.lexeme
  end

  # Executes the class body, creates a `ClassInstance`, and calls `setup` on it
  def construct(args : Array(ValueType)) : ClassInstance
    instance = ClassInstance.new(self, args)
    enclosing_this = @interpreter.meta["this"]?
    @interpreter.set_meta("this", instance)

    @interpreter.execute_block(@definition.body, Scope.new(@closure))
    if enclosing_this.nil?
      @interpreter.delete_meta("this")
    else
      @interpreter.set_meta("this", enclosing_this)
    end

    instance.setup
    instance
  end

  def to_s : String
    "<class: 0x#{@definition.object_id.to_s(16)}>"
  end
end
