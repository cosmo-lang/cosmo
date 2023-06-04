class Cosmo::StringIntrinsics
  def initialize(
    @interpreter : Interpreter,
    @value : String
  )
  end

  def get_method(name : Token) : IntrinsicFunction
    case name.lexeme.strip
    when "reverse"
      Reverse.new(@interpreter, @value, name)
    when "empty?"
      Empty.new(@interpreter, @value, name)
    when "numeric?"
      Numeric.new(@interpreter, @value, name)
    when "alphanumeric?"
      AlphaNumeric.new(@interpreter, @value, name)
    when "alpha?"
      Alpha.new(@interpreter, @value, name)
    when "without_last"
      WithoutLast.new(@interpreter, @value, name)
    when "without_first"
      WithoutFirst.new(@interpreter, @value, name)
    when "starts_with?"
      StartsWith.new(@interpreter, @value, name)
    when "ends_with?"
      EndsWith.new(@interpreter, @value, name)
    when "split"
      Split.new(@interpreter, @value, name)
    when "chars"
      Chars.new(@interpreter, @value, name)
    when "blank?"
      Blank.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid string method", name.lexeme, name)
    end
  end

  class Reverse < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : String
      @_self.reverse
    end
  end

  class Empty < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      @_self.chars.empty?
    end
  end

  class Numeric < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      !!(/[0-9]/ =~ @_self)
    end
  end

  class AlphaNumeric < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      !!(/[a-zA-Z0-9]/ =~ @_self)
    end
  end

  class Alpha < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      !!(/[a-zA-Z]/ =~ @_self)
    end
  end

  class WithoutFirst < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("int", args.first, token("string->without_last"))
      @_self[args.first.to_s.to_i .. (@_self.size - 1)].to_s
    end
  end

  class WithoutLast < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("int", args.first, token("string->without_last"))
      @_self[0 .. (-1 - args.first.to_s.to_i)].to_s
    end
  end

  class StartsWith < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Bool
      TypeChecker.assert("string|char", args.first, token("string->starts_with?"))
      @_self.starts_with?(args.first.to_s)
    end
  end

  class EndsWith < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Bool
      TypeChecker.assert("string|char", args.first, token("string->ends_with?"))
      @_self.ends_with?(args.first.to_s)
    end
  end

  class Split < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("string|char|void", args[0]?, token("string->split"))
      TypeChecker.array_as_value_type(@_self.split((args[0]? || " ").to_s))
    end
  end

  class Chars < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.array_as_value_type(@_self.chars)
    end
  end

  class Blank < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      @_self.blank?
    end
  end
end
