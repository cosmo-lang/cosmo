class Cosmo::NumberIntrinsics
  private alias Num = Int128 | Int64 | Int32 | Int16 | Int8 | Float64 | Float32

  def initialize(
    @interpreter : Interpreter,
    @value : Num
  )
  end

  def get_method(name : Token) : IntrinsicFunction
    case name.lexeme
    when "sqrt"
      Sqrt.new(@interpreter, @value, name)
    when "floor"
      Floor.new(@interpreter, @value, name)
    when "isqrt"
      ISqrt.new(@interpreter, @value, name)
    when "ceil"
      Ceil.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid number method", name.lexeme, name)
    end
  end

  class ISqrt < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Num,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int64
      TypeChecker.assert("int", @_self, token("Number->isqrt"))
      Math.isqrt(@_self.as Int64)
    end
  end

  class Sqrt < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Num,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int64 | Float64
      answer = Math.sqrt(@_self)
      answer.to_i == answer ? answer.to_i64 : answer.to_f64
    end
  end

  class Floor < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Num,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int64
      @_self.floor.to_i64
    end
  end

  class Ceil < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Num,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int64
      @_self.ceil.to_i64
    end
  end
end
