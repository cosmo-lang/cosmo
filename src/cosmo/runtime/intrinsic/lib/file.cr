require "file"

module Cosmo
  module Intrinsic
    class FileLib < Lib
      def inject : Nil
        file = {} of String => IFunction
        file["open"] = Open.new(@i)
        @i.declare_intrinsic("string->Function", "File", file)
      end
    end

    class Open < IFunction
      def arity : Range(UInt32, UInt32)
        1.to_u .. 1.to_u
      end

      def call(args : Array(ValueType)) : String
        if args.empty?
          return "Expected a file as an argument"
        else
          return File.read(Path.new(args.first.to_s))
        end
      end
    end
  end
end
