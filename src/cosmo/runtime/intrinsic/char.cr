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
    when "digit?"
      Digit.new(@interpreter, @value, name)
    when "letter?"
      Letter.new(@interpreter, @value, name)
    when "blank?"
      Blank.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid char method or property", name.lexeme, name)
    end
  end

  # Returns the UTF-16 codepoint of the character
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

  # Returns the uppercase equivalent of the character
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

  # Returns the lowercase equivalent of the character
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

  # Adds the `padding` character to the beginning and end of the character `size` times
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

    # `char padding`: The character to add to the end and beginning
    # `uint size`: How many times the `padding` character should be repeated
    def call(args : Array(ValueType)) : String
      TypeChecker.assert("char", args.first, token("char->pad"))
      TypeChecker.assert("uint", args[1], token("char->pad"))

      rep = args[1].as Int
      char = args.first.as Char
      char.to_s * rep + @_self.to_s + char.to_s * rep
    end
  end

  # Returns whether or not the given character is a digit
  class Digit < IFunction
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

  # Returns whether or not the given character is an english alphabet letter
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

  # Returns whether or not the given character is a whitespace character
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
