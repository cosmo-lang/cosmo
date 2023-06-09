module Cosmo::Intrinsic
  class Puts < IFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. MAX_FN_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Nil
      mapped : Array(String) = args.map do |arg|
        arg.is_a?(String | Char) ? arg.to_s : Util::Stringify.any_value(arg)
      end
      puts mapped.join("    ")
    end
  end
end
