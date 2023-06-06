module Cosmo::Intrinsic
  class Eval < IFunction
    def arity : Range(UInt32, UInt32)
      1.to_u .. 1.to_u
    end

    def call(args : Array(ValueType)) : ValueType # named argument here for adding history?
      TypeChecker.assert("string", args.first, token("eval"))

      interpreter = Interpreter.new(output_ast: false, run_benchmarks: false)
      interpreter.interpret(args.first.to_s, "eval:#{@interpreter.file_path}")
    end
  end
end
