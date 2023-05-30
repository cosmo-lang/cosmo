class Cosmo::StringIntrinsics
  def initialize(
    @interpreter : Interpreter,
    @value : String
  )
  end

  def get_method(name : Token) : IntrinsicFunction
    case name.lexeme
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
      TypeChecker.array_as_value_type(@_self.split((args[0]? || "").to_s))
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
