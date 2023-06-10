class Cosmo::Intrinsic::Vector
  def initialize(
    @interpreter : Interpreter,
    @cache : Array(ValueType)
  )
  end

  def get_method(name : Token) : IFunction
    case name.lexeme
    when "combine"
      Combine.new(@interpreter, @cache, name)
    when "delete"
      Delete.new(@interpreter, @cache, name)
    when "delete_at"
      DeleteAt.new(@interpreter, @cache, name)
    when "reverse"
      Reverse.new(@interpreter, @cache, name)
    when "rindex"
      RIndex.new(@interpreter, @cache, name)
    when "index"
      Index.new(@interpreter, @cache, name)
    when "includes?"
      Includes.new(@interpreter, @cache, name)
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

  class Combine < IFunction
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
      TypeChecker.assert("any[]", args.first, token("Vector->combine"))
      @_self + args.first.as Array(ValueType)
    end
  end

  class DeleteAt < IFunction
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

    def call(args : Array(ValueType)) : Array(ValueType)
      t = token("Vector->delete_at")
      TypeChecker.assert("uint", args.first, t)
      TypeChecker.assert("uint?", args[1]?, t)
      if @_self[args.first.as Int].nil?
        Logger.report_error("Failed to delete vector value", "Value does not exist at index #{args.first} in vector", t)
      else
        if args[1]?.nil?
          @_self.delete_at(args.first.as Int)
          @_self
        else
          @_self.delete_at(args.first.as Int, args[1]?.as Int)
        end
      end
    end
  end

  class Delete < IFunction
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
      idx = @_self.index(0) { |e| e == args.first }
      if idx.nil?
        Logger.report_error(
          "Failed to delete vector value",
          "Value '#{Util::Stringify.any_value(args.first)}' does not exist in vector",
          token("Vector->delete")
        )
      else
        @_self.delete_at(idx)
        @_self
      end
    end
  end

  class Reverse < IFunction
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

    def call(args : Array(ValueType)) : Array(ValueType)
      @_self.reverse
    end
  end

  class Includes < IFunction
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

    def call(args : Array(ValueType)) : Bool
      @_self.includes?(args.first)
    end
  end

  class RIndex < IFunction
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
      TypeChecker.assert("int?", offset, token("Vector->rindex"))

      t_offset : Int64? = offset.as? Int64
      n_offset : Int64 = t_offset.nil? ? -1_i64 : t_offset
      @_self.rindex(n_offset) { |e| e == args.first }
    end
  end

  class Index < IFunction
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

  class IsEmpty < IFunction
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

  class Sort < IFunction
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

    def call(args : Array(ValueType)) : Array(ValueType)
      TypeChecker.assert("Function?", args.first?, token("Vector->sort"))

      sorter = args.first?.as Callable?
      res = @_self.map { |v| TypeChecker.as_value_type(v) }.sort do |a, b|
        value = sorter.nil? ? a.as Num - b.as Num : sorter.call([a, b])
        TypeChecker.assert("int|float", value, token("Vector->sort"))
        value.as(Num).to_i unless value.nil?
      end

      res.map(&.as ValueType)
    end
  end

  class Join < IFunction
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

  class Shift < IFunction
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

  class Push < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : Array(ValueType),
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. MAX_FN_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Array(ValueType)
      args.each do |arg|
        @_self << arg
      end
      @_self
    end
  end

  class Pop < IFunction
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

  class Sum < IFunction
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

  class FirstNullable < IFunction
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

  class LastNullable < IFunction
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

  class First < IFunction
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

  class Last < IFunction
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

  class Map < IFunction
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
      TypeChecker.assert("Function", args.first, token("Vector->map"))
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

  class Filter < IFunction
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
      TypeChecker.assert("Function", args.first, token("Vector->filter"))
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
