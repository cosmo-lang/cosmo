MAX_INTRINSIC_PARAMS = 255

module Cosmo
  abstract class IntrinsicFunction < Callable
    def initialize(@interpreter : Interpreter)
    end

    abstract def call(args : Array(ValueType)) : ValueType

    def intrinsic? : Bool
      true
    end

    def token(name : String) : Token
      location = Location.new("intrinsic", 0, 0)
      Token.new(name, Syntax::Identifier, name, location)
    end

    def to_s : String
      "<intrinsic ##{self.hash}>"
    end
  end

  class PutsIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Nil
      @interpreter.set_meta("block_return_type", "void")
      puts args.map { |arg| arg.nil? ? "none" : arg.to_s}.join('\t')
    end
  end

  class SqrtIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float | int", args.first, token("sqrt"))
      x = args.first.as Float64
      return Float64::NAN if x < 0
      Math.sqrt(x)
    end
  end
end
