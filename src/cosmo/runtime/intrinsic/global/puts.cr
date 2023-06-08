module Cosmo::Intrinsic
  class Puts < IFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. MAX_FN_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Nil
      mapped = args.map do |arg|
        Stringify.any_value(arg)
      end
      puts mapped.join("    ")
    end
  end
end
