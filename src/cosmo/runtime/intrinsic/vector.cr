class Cosmo::VectorIntrinsics
  def initialize(
    @interpreter : Interpreter,
    @cache : Array(ValueType)
  )
  end

  def get_method(name : Token) : IntrinsicFunction
    case name.lexeme
    when "index"
      Index.new(@interpreter, @cache, name)
    when "empty?"
      IsEmpty.new(@interpreter, @cache, name)
    when "sort"
      Sort.new(@interpreter, @cache, name)
    when "join"
      Join.new(@interpreter, @cache, name)
    when "push"
      Push.new(@interpreter, @cache, name)
    when "pop"
      Pop.new(@interpreter, @cache, name)
    when "shift"
      Shift.new(@interpreter, @cache, name)
    when "first"
      First.new(@interpreter, @cache, name)
    when "last"
      Last.new(@interpreter, @cache, name)
    when "first?"
      FirstNullable.new(@interpreter, @cache, name)
    when "last?"
      LastNullable.new(@interpreter, @cache, name)
    when "sum"
      Sum.new(@interpreter, @cache, name)
    when "filter"
      Filter.new(@interpreter, @cache, name)
    when "map"
      Map.new(@interpreter, @cache, name)
    else
      Logger.report_error("Invalid vector method or property", name.lexeme, name)
    end
  end

  class Index < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : Int64?
      offset = args[1]?
      TypeChecker.assert("int?", offset, token("Vector->index"))

      t_offset : Int64? = offset.as? Int64
      n_offset : Int64 = t_offset.nil? ? 0_i64 : t_offset
      @_self.index(n_offset) { |e| e == args.first }
    end
  end

  class IsEmpty < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
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

  class Sort < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->sort"))

      if args.first.is_a?(Callable)
        sorter = args.first.as Callable
        res = @_self.map { |v| TypeChecker.as_value_type(v) }.sort do |a, b|
          value = sorter.call([a, b])
          TypeChecker.assert("int|float", value, token("Vector->sort"))
          value.as(Num).to_i unless value.nil?
        end
        res.map(&.as ValueType)
      else
        [] of ValueType
      end
    end
  end

  class Join < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("string|char|void", args[0]?, token("Vector->join"))
      @_self.join((args[0]? || " ").to_s)
    end
  end

  class Shift < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      @_self.shift
    end
  end

  class Push < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      args.each do |arg|
        @_self << arg
      end
      @_self
    end
  end

  class Pop < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      @_self.pop
    end
  end

  class Sum < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : Num
      TypeChecker.assert("float|int[]", @_self, token("Vector->sum"))
      sum = @_self.map { |e| e.as Num }.sum
      sum.to_i == sum ? sum.to_i64 : sum.to_f64
    end
  end

  class FirstNullable < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      @_self[0]?
    end
  end

  class LastNullable < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      @_self[@_self.size - 1]?
    end
  end

  class First < IntrinsicFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      value = @_self[0]?
      if value.nil?
        Logger.report_error("Index out of bounds", "Index 0, array size #{@_self.size}", token("Vector->first"))
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
      0.to_u .. 0.to_u
    end

    def call(args : Array(ValueType)) : ValueType
      i = @_self.size - 1
      value = @_self[i]?
      if value.nil?
        Logger.report_error("Index out of bounds", "Index #{i}, array size #{@_self.size}", token("Vector->last"))
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
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->map"))
      if args.first.is_a?(Callable)
        fn = args.first.as Callable
        res = [] of ValueType

        @_self.each_with_index do |v, i|
          res << fn.call([v, i])
        end

        res
      else
        [] of ValueType
      end
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
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("func", args.first, token("Vector->filter"))
      if args.first.is_a?(Callable)
        fn = args.first.as Callable

        @_self.select do |v|
          fn.call([v])
        end
      else
        [] of ValueType
      end
    end
  end
end
