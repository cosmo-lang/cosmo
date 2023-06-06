module Cosmo::Intrinsic
  class Puts < IFunction
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
end
