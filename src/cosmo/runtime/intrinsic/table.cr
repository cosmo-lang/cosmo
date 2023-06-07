class Cosmo::Intrinsic::Table
  def initialize(
    @interpreter : Interpreter,
    @value : Hash(ValueType, ValueType)
  )
  end

  def get_method(name : Token, required = true) : IFunction?
    case name.lexeme.strip
    when "keys"
      Keys.new(@interpreter, @value, name)
    when "values"
      Values.new(@interpreter, @value, name)
    when "invert"
      Invert.new(@interpreter, @value, name)
    when "has?"
      Has.new(@interpreter, @value, name)
    when "empty?"
      Empty.new(@interpreter, @value, name)
    else
      Logger.report_error("Invalid table method or property", name.lexeme, name) if required
    end
  end

  class Keys < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Hash(ValueType, ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      keys = [] of ValueType
      @_self.each_key { |v| keys << v}
      keys
    end
  end

  class Values < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Hash(ValueType, ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      values = [] of ValueType
      @_self.each_value { |v| values << v}
      values
    end
  end

  class Empty < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Hash(ValueType, ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Bool
      @_self.empty?
    end
  end

  class Has < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Hash(ValueType, ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Bool
      @_self.has_key?(args.first)
    end
  end

  class Invert < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Hash(ValueType, ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Hash(ValueType, ValueType)
      @_self.invert
    end
  end
end
