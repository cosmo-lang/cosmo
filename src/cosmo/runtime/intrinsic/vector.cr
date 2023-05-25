class Cosmo::VectorIntrinsics
  def initialize(
    @interpreter : Interpreter,
    @cache : Array(ValueType)
  )
  end

  def get_method(name : Token) #: IntrinsicFunction
    case name.lexeme
    when "first"
      First.new(@interpreter, @cache, name)
    when "last"
      Last.new(@interpreter, @cache, name)
    # when "first?"
    #   FirstNullable.new(@interpreter, @cache, name)
    # when "last?"
    #   LastNullable.new(@interpreter, @cache, name)
    when "filter"
      Filter.new(@interpreter, @cache, name)
    when "map"
      Map.new(@interpreter, @cache, name)
    else
      Logger.report_error("Invalid vector method", name.lexeme, name)
    end
  end

  # class FirstNullable < IntrinsicFunction
  #   def initialize(
  #     interpreter : Interpreter,
  #     @_self : Array(ValueType),
  #     @token : Token
  #   )

  #     super interpreter
  #   end

  #   def arity : Range(UInt32, UInt32)
  #     0.to_u..0.to_u
  #   end

  #   def call(args : Array(ValueType)) : ValueType
  #     @_self[0]?
  #   end
  # end

  # class LastNullable < IntrinsicFunction
  #   def initialize(
  #     interpreter : Interpreter,
  #     @_self : Array(ValueType),
  #     @token : Token
  #   )

  #     super interpreter
  #   end

  #   def arity : Range(UInt32, UInt32)
  #     0.to_u..0.to_u
  #   end

  #   def call(args : Array(ValueType)) : ValueType
  #     @_self[@_self.size - 1]?
  #   end
  # end

  class First < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u..0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      value = @_self[0]?
      if value.nil?
        Logger.report_error("Index out of bounds", "Index 0, array size #{@_self.size}", @token)
      end
      value
    end
  end

  class Last < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u..0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      i = @_self.size - 1
      value = @_self[i]?
      if value.nil?
        Logger.report_error("Index out of bounds", "Index #{i}, array size #{@_self.size}", @token)
      end
      value
    end
  end

  class Map < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

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
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

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
