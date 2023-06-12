require "file"

module Cosmo
  module Intrinsic
    class FileLib < Lib
      def inject : Nil
        file = {} of String => IFunction
        file["read"] = Read.new(@i)
        file["write"] = Write.new(@i)
        file["append"] = Append.new(@i)

        @i.declare_intrinsic("string->Function", "File", file)
      end
    end

    # TODO: catch any errors thrown
    class Append < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 2.to_u
      end

      def call(args : Array(ValueType)) : Nil
        return File.write(args.first.to_s, args[1].to_s, mode: "a")
      end
    end

    class Write < IFunction
      def arity : Range(UInt32, UInt32)
        2.to_u .. 2.to_u
      end

      def call(args : Array(ValueType)) : Nil
        return File.write(args.first.to_s, args[1].to_s)
      end
    end

    class Read < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : String
        return File.read(args.first.to_s)
      end
    end
  end
end
