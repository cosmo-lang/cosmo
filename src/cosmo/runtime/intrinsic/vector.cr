class Cosmo::VectorIntrinsics(T)
  def initialize(
    @interpreter : Interpreter,
    @cache : Array(T)
  )
  end

  def get_method(name : Token) #: IntrinsicFunction
    case name.lexeme
    when "filter"
      Filter(T).new(@interpreter, @cache)
    else
      Logger.report_error("Invalid vector method", name.lexeme, name)
    end
  end

  class Filter(T) < IntrinsicFunction
    def initialize(interpreter : Interpreter, @_self : Array(T))
      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->filter"))
      fn = args.first.as(Callable)
      i = 0
      @_self.select do |v|
        keep = fn.call([v, i])
        i += 1
        keep
      end
    end
  end
end
