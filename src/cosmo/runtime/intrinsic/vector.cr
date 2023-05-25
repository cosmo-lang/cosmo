class Cosmo::VectorIntrinsics
  def initialize(
    @interpreter : Interpreter,
    @cache : Array(ValueType)
  )
  end

  def get_method(name : Token) #: IntrinsicFunction
    case name.lexeme
    when "filter"
      Filter.new(@interpreter, @cache)
    when "map"
      Map.new(@interpreter, @cache)
    else
      Logger.report_error("Invalid vector method", name.lexeme, name)
    end
  end

  class Map < IntrinsicFunction
    def initialize(interpreter : Interpreter, @_self : Array(ValueType))
      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->map"))
      fn = args.first.as(Callable)

      res = [] of ValueType
      @_self.each do |v|
        res << fn.call([v])
      end
      res
    end
  end

  class Filter < IntrinsicFunction
    def initialize(interpreter : Interpreter, @_self : Array(ValueType))
      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->filter"))
      fn = args.first.as(Callable)
      @_self.select do |v|
        fn.call([v])
      end
    end
  end
end
