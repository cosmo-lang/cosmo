class Cosmo::Intrinsic::Chars
  def initialize(
    @interpreter : Interpreter,
    @value : Char
  )
  end

  def get_method(name : Token) : IFunction
    case name.lexeme.strip
    when "codepoint"
      Codepoint.new(@interpreter, @value, name)
    when "lower"
      Lower.new(@interpreter, @value, name)
    when "upper"
      Upper.new(@interpreter, @value, name)
    when "pad"
      Pad.new(@interpreter, @value, name)
    when "number?"
      NumberF.new(@interpreter, @value, name)
    when "letter?"
      Letter.new(@interpreter, @value, name)
    when "blank?"
      Blank.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid char method or property", name.lexeme, name)
    end
  end

  class Codepoint < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int
      @_self.ord
    end
  end

  class Codepoint < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Int32?
      @_self.ord
    end
  end

  class Upper < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Char
      @_self.to_s.upcase.chars.first
    end
  end

  class Lower < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Char
      @_self.to_s.downcase.chars.first
    end
  end

  class Pad < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      2.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("char", args.first, token("char->pad"))
      TypeChecker.assert("uint", args[1], token("char->pad"))

      rep = args[1].as Int
      char = args.first.as Char
      char.to_s * rep + @_self.to_s + char.to_s * rep
    end
  end

  class NumberF < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      !!(/[0-9]/ =~ @_self.to_s)
    end
  end

  class Letter < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      !!(/[a-zA-Z]/ =~ @_self.to_s)
    end
  end

  class Blank < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Char,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      @_self.to_s.blank?
    end
  end
end
