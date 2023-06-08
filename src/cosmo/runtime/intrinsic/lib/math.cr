module Cosmo::Intrinsic
  class MathLib < Lib
    def inject : Nil
      math = {} of String => IFunction | Float64
      math["e"] = Math::E
      math["π"] = Math::PI
      math["inf"] = Float64::INFINITY
      math["random"] = Random.new(@i)
      math["min"] = Min.new(@i)
      math["max"] = Max.new(@i)
      math["log"] = Log.new(@i)
      math["log2"] = Log2.new(@i)
      math["log10"] = Log10.new(@i)
      math["exp"] = Exp.new(@i)
      math["sin"] = Sin.new(@i)
      math["cos"] = Cos.new(@i)
      math["tan"] = Tan.new(@i)
      math["sinh"] = Sinh.new(@i)
      math["cosh"] = Cosh.new(@i)
      math["tanh"] = Tanh.new(@i)
      math["asinh"] = Asinh.new(@i)
      math["acosh"] = Acosh.new(@i)
      math["atanh"] = Atanh.new(@i)
      math["asin"] = Asin.new(@i)
      math["acos"] = Acos.new(@i)
      math["atan"] = Atan.new(@i)
      math["atan2"] = Atan2.new(@i)

      @i.declare_intrinsic("string->(Function|float)", "Math", math)
    end

    class Random < IFunction
      def arity : Range(UInt32, UInt32)
        0.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Num
        TypeChecker.assert("Range|float|int|void", args.first?, token("Math->random"))
        if args.empty?
          rand
        elsif args.first.is_a?(Num)
          rand(args.first.as Num)
        else
          r = args.first.as(Range)
          if r.begin.is_a?(Int)
            a = r.to_a.map(&.to_i)
            rand(a.first .. a.last)
          else
            a = r.to_a.map(&.to_f)
            rand(a.first .. a.last)
          end
        end
      end
    end

    class Min < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. MAX_FN_PARAMS.to_u
      end

      def call(args : Array(ValueType)) : Num
        args.each do |arg|
          TypeChecker.assert("float|int", arg, token("Math->min"))
        end

        min = args.first.as Number
        args.shift
        args.each do |arg|
          min = Math.min(arg.as Number, min)
        end

        min.as Num
      end
    end

    class Max < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. MAX_FN_PARAMS.to_u
      end

      def call(args : Array(ValueType)) : Num
        args.each do |arg|
          TypeChecker.assert("float|int", arg, token("Math->max"))
        end

        max = args.first.as Number
        args.shift
        args.each do |arg|
          max = Math.max(arg.as Number, max)
        end

        max.as Num
      end
    end

    class Log2 < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->exp"))
        x = args.first.as Number
        Math.log2(x).to_f64
      end
    end

    class Log10 < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->exp"))
        x = args.first.as Number
        Math.log10(x).to_f64
      end
    end

    class Log < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->exp"))
        x = args.first.as Number
        Math.log(x).to_f64
      end
    end

    class Exp < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->exp"))
        x = args.first.as Number
        Math.exp(x).to_f64
      end
    end

    class Sin < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->sin"))
        x = args.first.as Number
        Math.sin(x).to_f64
      end
    end

    class Cos < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->cos"))
        x = args.first.as Number
        Math.cos(x).to_f64
      end
    end

    class Tan < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->tan"))
        x = args.first.as Number
        Math.tan(x).to_f64
      end
    end

    class Asin < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->asin"))
        x = args.first.as Number
        Math.asin(x).to_f64
      end
    end

    class Acos < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->acos"))
        x = args.first.as(Float64)
        Math.acos(x).to_f64
      end
    end

    class Atan < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->atan"))
        x = args.first.as Number
        Math.atan(x).to_f64
      end
    end

    class Atan2 < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u..2.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->atan2"))
        y = args.first.as Number
        x = args.last.as Number
        Math.atan2(y, x).to_f64
      end
    end

    class Sinh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->sinh"))
        x = args.first.as Number
        Math.sinh(x).to_f64
      end
    end

    class Cosh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->cosh"))
        x = args.first.as Number
        Math.cosh(x).to_f64
      end
    end

    class Tanh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->tanh"))
        x = args.first.as Number
        Math.tanh(x).to_f64
      end
    end

    class Asinh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->asinh"))
        x = args.first.as Number
        Math.asinh(x).to_f64
      end
    end

    class Acosh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->acosh"))
        x = args.first.as Number
        Math.acosh(x).to_f64
      end
    end

    class Atanh < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u..1.to_u
      end

      def call(args : Array(ValueType)) : Float64
        TypeChecker.assert("float|int", args.first, token("Math->atanh"))
        x = args.first.as Number
        Math.atanh(x).to_f64
      end
    end
  end
end
