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
      "<intrinsic ##{self.object_id.to_s(16)}>"
    end
  end

  abstract class IntrinsicLib
    def initialize(@i : Interpreter)
    end

    abstract def inject : Nil
  end

  class PutsIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Nil
      mapped = args.map do |arg|
        if arg.nil?
          "none"
        elsif arg.is_a?(Hash)
          Stringify.hashmap(arg.as Hash(ValueType, ValueType))
        else
          arg.to_s
        end
      end

      puts mapped.join('\t')
    end
  end

  class GetsIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : String? # named argument here for adding history?
      TypeChecker.assert("string|char", args.first, token("gets"))
      STDOUT.write(args.first.to_s.to_slice)
      STDIN.gets
    end
  end

  class RecursionDepthIntrinsic < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Nil
      TypeChecker.assert("uint", args.first, token("recursion_depth!"))
      @interpreter.max_recursion_depth = args.first.as UInt32 if args.first.is_a?(UInt32)
    end
  end
end
