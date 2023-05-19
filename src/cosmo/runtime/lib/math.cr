module Cosmo::MathLib
  def self.inject(i : Interpreter)
    math_lib = {} of String => IntrinsicFunction | Float64
    math_lib["e"] = Math::E
    math_lib["pi"] = Math::PI
    math_lib["floor"] = Floor.new(i)
    math_lib["ceil"] = Ceil.new(i)
    math_lib["round"] = Round.new(i)
    math_lib["min"] = Min.new(i)
    math_lib["max"] = Max.new(i)
    math_lib["log"] = Log.new(i)
    math_lib["log2"] = Log2.new(i)
    math_lib["log10"] = Log10.new(i)
    math_lib["exp"] = Exp.new(i)
    math_lib["sqrt"] = Sqrt.new(i)
    math_lib["isqrt"] = Isqrt.new(i)
    math_lib["cbrt"] = Cbrt.new(i)
    math_lib["sin"] = Sin.new(i)
    math_lib["cos"] = Cos.new(i)
    math_lib["tan"] = Tan.new(i)
    math_lib["sinh"] = Sinh.new(i)
    math_lib["cosh"] = Cosh.new(i)
    math_lib["tanh"] = Tanh.new(i)
    math_lib["asinh"] = Asinh.new(i)
    math_lib["acosh"] = Acosh.new(i)
    math_lib["atanh"] = Atanh.new(i)
    math_lib["asin"] = Asin.new(i)
    math_lib["acos"] = Acos.new(i)
    math_lib["atan"] = Atan.new(i)
    math_lib["atan2"] = Atan2.new(i)
    i.declare_intrinsic("string->(func|float)", "Math", math_lib)
  end

  class Floor < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Int64
      @interpreter.set_meta("block_return_type", "int")
      TypeChecker.assert("float|int", args.first, token("exp"))
      args.first.as(Number).round(:to_negative).to_i64
    end
  end

  class Ceil < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Int64
      @interpreter.set_meta("block_return_type", "int")
      TypeChecker.assert("float|int", args.first, token("exp"))
      args.first.as(Number).round(:to_positive).to_i64
    end
  end

  class Round < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      2.to_u..2.to_u
    end

    def call(args : Array(ValueType)) : Float64 | Int64
      @interpreter.set_meta("block_return_type", "float|int")
      TypeChecker.assert("float|int", args.first, token("round"))
      TypeChecker.assert("int", args.last, token("round"))

      n = args.first.as Number
      d = args.last.as Int64
      n.round(d).as(Float64 | Int64)
    end
  end

  class Min < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      2.to_u..MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Float64 | Int64
      @interpreter.set_meta("block_return_type", "float|int")
      args.each do |arg|
        TypeChecker.assert("float|int", arg, token("min"))
      end

      min = args.first.as Number
      args.shift
      args.each do |arg|
        min = Math.min(arg.as Number, min)
      end
      min.as(Float64 | Int64)
    end
  end

  class Max < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      2.to_u..MAX_INTRINSIC_PARAMS.to_u
    end

    def call(args : Array(ValueType)) : Float64 | Int64
      @interpreter.set_meta("block_return_type", "float|int")
      args.each do |arg|
        TypeChecker.assert("float|int", arg, token("max"))
      end

      max = args.first.as Number
      args.shift
      args.each do |arg|
        max = Math.max(arg.as Number, max)
      end
      max.as(Float64 | Int64)
    end
  end

  class Log2 < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("exp"))
      x = args.first.as Number
      Math.log2(x).to_f64
    end
  end

  class Log10 < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("exp"))
      x = args.first.as Number
      Math.log10(x).to_f64
    end
  end

  class Log < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("exp"))
      x = args.first.as Number
      Math.log(x).to_f64
    end
  end

  class Exp < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("exp"))
      x = args.first.as Number
      Math.exp(x).to_f64
    end
  end

  class Isqrt < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("int", args.first, token("isqrt"))
      Math.isqrt(args.first.as Int64).to_f64
    end
  end

  class Sqrt < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("sqrt"))
      x = args.first.as Number
      Math.sqrt(x).to_f64
    end
  end

  class Cbrt < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("cbrt"))
      x = args.first.as Number
      Math.cbrt(x).to_f64
    end
  end

  class Sin < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("sin"))
      x = args.first.as Number
      Math.sin(x).to_f64
    end
  end

  class Cos < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("cos"))
      x = args.first.as Number
      Math.cos(x).to_f64
    end
  end

  class Tan < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("tan"))
      x = args.first.as Number
      Math.tan(x).to_f64
    end
  end

  class Asin < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("asin"))
      x = args.first.as Number
      Math.asin(x).to_f64
    end
  end

  class Acos < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("acos"))
      x = args.first.as(Float64)
      Math.acos(x).to_f64
    end
  end

  class Atan < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("atan"))
      x = args.first.as Number
      Math.atan(x).to_f64
    end
  end

  class Atan2 < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      2.to_u..2.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("atan2"))
      y = args.first.as Number
      x = args.last.as Number
      Math.atan2(y, x).to_f64
    end
  end

  class Sinh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("sinh"))
      x = args.first.as Number
      Math.sinh(x).to_f64
    end
  end

  class Cosh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("cosh"))
      x = args.first.as Number
      Math.cosh(x).to_f64
    end
  end

  class Tanh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("tanh"))
      x = args.first.as Number
      Math.tanh(x).to_f64
    end
  end

  class Asinh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("asinh"))
      x = args.first.as Number
      Math.asinh(x).to_f64
    end
  end

  class Acosh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("acosh"))
      x = args.first.as Number
      Math.acosh(x).to_f64
    end
  end

  class Atanh < IntrinsicFunction
    def arity : Range(UInt32, UInt32)
      1.to_u..1.to_u
    end

    def call(args : Array(ValueType)) : Float64
      @interpreter.set_meta("block_return_type", "float")
      TypeChecker.assert("float|int", args.first, token("atanh"))
      x = args.first.as Number
      Math.atanh(x).to_f64
    end
  end
end
