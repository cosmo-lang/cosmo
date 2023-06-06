module Cosmo
  alias Num = Int128 | Int64 | Int32 | Int16 | Int8 | Float64 | Float32 | UInt
end

class Cosmo::Intrinsic::Numbers
  def initialize(
    @interpreter : Interpreter,
    @value : Num
  )
  end

  def get_method(name : Token) : IFunction
    case name.lexeme
    when "cbrt"
      Cbrt.new(@interpreter, @value, name)
    when "isqrt"
      ISqrt.new(@interpreter, @value, name)
    when "sqrt"
      Sqrt.new(@interpreter, @value, name)
    when "floor"
      Floor.new(@interpreter, @value, name)
    when "round"
      Round.new(@interpreter, @value, name)
    when "ceil"
      Ceil.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid number method or property", name.lexeme, name)
    end
  end

  class Cbrt < IFunction
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

    def call(args : Array(ValueType)) : Num
      Math.cbrt(@_self)
    end
  end

  class ISqrt < IFunction
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

  class Sqrt < IFunction
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

    def call(args : Array(ValueType)) : Num
      answer = Math.sqrt(@_self)
      answer.to_i == answer ? answer.to_i64 : answer.to_f64
    end
  end

  class Round < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Num,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Num
      TypeChecker.assert("int", args.first, token("Number->round"))

      decimal_place = args.first.to_s.to_i64
      @_self.round(decimal_place).as Num
    end
  end

  class Floor < IFunction
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

  class Ceil < IFunction
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
