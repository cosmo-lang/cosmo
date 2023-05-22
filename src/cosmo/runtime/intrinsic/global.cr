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

  abstract class IntrinsicLib
    def initialize(@i : Interpreter)
    end

    abstract def inject : Nil
  end

  class PutsIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Nil
      @interpreter.set_meta("block_return_type", "void")
      mapped = args.map do |arg|
        return "none" if arg.nil?
        return arg.to_s unless arg.is_a?(Hash)
        Stringify.hashmap(arg.as Hash(ValueType, ValueType))
      end

      puts mapped.join('\t')
    end
  end
end
