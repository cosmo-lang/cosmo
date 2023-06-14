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
    when "zero_pad"
      ZeroPad.new(@interpreter, @value, name)
    when "to_hex"
      ToHex.new(@interpreter, @value, name)
    when "to_binary"
      ToBinary.new(@interpreter, @value, name)
    when "to_utf16"
      ToUtf16.new(@interpreter, @value, name)
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

  # Adds `width` - `#<string>n` zeros to the front of the string
  class ZeroPad < IFunction
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

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("uint", @_self, token("string->zero_pad"))
      TypeChecker.assert("uint", args.first, token("string->zero_pad"))

      width = args.first.as Int
      ("0" * Math.max(width - @_self.to_s.size, 0)) + @_self.to_s
    end
  end

  # Returns the hexadecimal representation of the number
  class ToHex < IFunction
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

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("int", @_self, token("Number->to_binary"))
      @_self.to_i.to_s(16)
    end
  end

  # Returns the binary representation of the number
  class ToBinary < IFunction
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

    def call(args : Array(ValueType)) : Int64 | Int32
      TypeChecker.assert("int", @_self, token("Number->to_binary"))
      @_self.to_i.to_s(2).to_i
    end
  end

  # Converts the number to a character as a UTF-16 codepoint
  class ToUtf16 < IFunction
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

    def call(args : Array(ValueType)) : Char
      t = token("Number->to_utf16")
      TypeChecker.assert("uint", @_self, t)
      if @_self > 65536
        Logger.report_error("Invalid UTF-16 codepoint", "Given codepoint '#{@_self}' is larger than 16 bytes", t)
      end

      as_uint = @_self.to_u16
      String.from_utf16(pointerof(as_uint)).first.chars.first
    end
  end

  # Returns the cube root of the number
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

  # Returns the integer square root of the number
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

  # Returns the square root of the number
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

  # Returns the number rounded to the `n`th decimal point
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

    # `uint n`: The decimal point to round to
    def call(args : Array(ValueType)) : Num
      TypeChecker.assert("uint", args.first, token("Number->round"))

      decimal_place = args.first.to_s.to_i64
      @_self.round(decimal_place).as Num
    end
  end

  # Returns the number rounded down
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

  # Returns the number rounded up
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
