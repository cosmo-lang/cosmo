module Cosmo::Intrinsic
  class Gets < IFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : String? # named argument here for adding history?
      TypeChecker.assert("string|char", args.first, token("gets"))
      STDOUT.write(args.first.to_s.to_slice)
      STDIN.gets
    end
  end
end
