class Cosmo::Intrinsic::Ranges
  private alias I = Int128 | Int64 | Int32 | Int16 | Int8 | UInt
  def initialize(
    @interpreter : Interpreter,
    @value : RangeType
  )
  end

  def get_method(name : Token) : IFunction
    case name.lexeme
    when "begin"
      Begin.new(@interpreter, @value, name)
    when "end"
      End.new(@interpreter, @value, name)
    when "sum"
      Sum.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid number method or property", name.lexeme, name)
    end
  end

  # Returns the first number of the range
  class Begin < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : RangeType,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : I
      @_self.begin
    end
  end

  # Returns the last number of the range
  class End < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : RangeType,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : I
      @_self.end
    end
  end

  # Returns the sum of all numbers in the range
  class Sum < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : RangeType,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : I
      @_self.sum
    end
  end
end
