module Cosmo::Intrinsic
  class RecursionDepth < IFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : Nil
      TypeChecker.assert("uint", args.first, token("recursion_depth!"))
      @interpreter.max_recursion_depth = args.first.as(Int).to_u
    end
  end
end
