class Cosmo::Intrinsic::Strings
  def initialize(
    @interpreter : Interpreter,
    @value : String
  )
  end

  def get_method(name : Token) : IFunction
    case name.lexeme.strip
    when "index"
      Index.new(@interpreter, @value, name)
    when "rindex"
      RIndex.new(@interpreter, @value, name)
    when "lchop"
      LChop.new(@interpreter, @value, name)
    when "rchop"
      RChop.new(@interpreter, @value, name)
    when "ltrim"
      LTrim.new(@interpreter, @value, name)
    when "rtrim"
      RTrim.new(@interpreter, @value, name)
    when "trim"
      Trim.new(@interpreter, @value, name)
    when "pad"
      Pad.new(@interpreter, @value, name)
    when "lower"
      Lower.new(@interpreter, @value, name)
    when "upper"
      Upper.new(@interpreter, @value, name)
    when "pascal_case"
      PascalCase.new(@interpreter, @value, name)
    when "title_case"
      TitleCase.new(@interpreter, @value, name)
    when "snake_case"
      SnakeCase.new(@interpreter, @value, name)
    when "capitalize"
      Capitalize.new(@interpreter, @value, name)
    when "replace"
      Replace.new(@interpreter, @value, name)
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
      Logger.report_error("Invalid string method or property", name.lexeme, name)
    end
  end

  class Replace < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      2.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("string|char", args.first, token("string->replace"))
      TypeChecker.assert("string|char", args[1], token("string->replace"))
      @_self.gsub(args.first.to_s, args[1].to_s)
    end
  end

  class Capitalize < IFunction
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
      @_self.capitalize
    end
  end

  class SnakeCase < IFunction
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
      @_self.underscore
    end
  end

  class TitleCase < IFunction
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
      @_self.titleize
    end
  end

  class CamelCase < IFunction
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
      chars = @_self.camelcase.chars
      chars[0] = chars[0].downcase
      chars.join
    end
  end

  class PascalCase < IFunction
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
      @_self.camelcase
    end
  end

  class Upper < IFunction
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
      @_self.upcase
    end
  end

  class Lower < IFunction
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
      @_self.downcase
    end
  end

  class Pad < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      2.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : String
      TypeChecker.assert("char", args.first, token("string->pad"))
      TypeChecker.assert("uint", args[1], token("string->pad"))
      @_self.center(args[1].as Int, args.first.to_s.chars.first)
    end
  end

  class Trim < IFunction
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
      @_self.strip
    end
  end

  class LTrim < IFunction
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
      @_self.lstrip
    end
  end

  class RTrim < IFunction
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
      @_self.rstrip
    end
  end

  class LChop < IFunction
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
      @_self.lchop
    end
  end

  class RChop < IFunction
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
      @_self.rchop
    end
  end

  class Includes < IFunction
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
      TypeChecker.assert("string|char", args.first, token("string->includes?"))
      @_self.includes?(args.first.to_s)
    end
  end

  class RIndex < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : Int32?
      TypeChecker.assert("string|char", args.first, token("string->rindex"))
      offset = args[1]?
      TypeChecker.assert("int?", offset, token("string->rindex"))

      t_offset : Int64? = offset.as? Int64
      n_offset : Int64 = t_offset.nil? ? -1_i64 : t_offset
      res = @_self.rindex(args.first.to_s, n_offset)
      return nil if res.nil?
      res.to_i
    end
  end

  class Index < IFunction
    def initialize(
      interpreter : Interpreter,
      @_self : String,
      @token : Token
    )

      super interpreter
    end

    def arity : Range(UInt32, UInt32)
      1.to_u .. 2.to_u
    end

    def call(args : Array(ValueType)) : Int32?
      TypeChecker.assert("string|char", args.first, token("string->index"))
      offset = args[1]?
      TypeChecker.assert("int?", offset, token("string->index"))

      t_offset : Int64? = offset.as? Int64
      n_offset : Int64 = t_offset.nil? ? 0_i64 : t_offset
      res = @_self.index(args.first.to_s, n_offset)
      return nil if res.nil?
      res.to_i
    end
  end

  class Reverse < IFunction
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

  class Empty < IFunction
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

  class Numeric < IFunction
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

  class AlphaNumeric < IFunction
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

  class Alpha < IFunction
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

  class WithoutFirst < IFunction
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

  class WithoutLast < IFunction
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

  class StartsWith < IFunction
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

  class EndsWith < IFunction
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

  class Split < IFunction
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

  class Chars < IFunction
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

  class Blank < IFunction
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
