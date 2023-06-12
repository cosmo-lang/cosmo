require "file"

module Cosmo
  module Intrinsic
    class FileLib < Lib
      def inject : Nil
        file = {} of String => IFunction
        file["read"] = Read.new(@i)
        file["write"] = Write.new(@i)
        file["append"] = Append.new(@i)
        file["delete"] = Delete.new(@i)
        file["exists?"] = Exists.new(@i)
        file["directory?"] = Directory.new(@i)
        file["empty?"] = Empty.new(@i)

        @i.declare_intrinsic("string->Function", "File", file)
      end

      # Checks whether or not the given file has no contents
      class Empty < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : Bool
          t = token("File->empty?")
          TypeChecker.assert("string", args.first, t)
          begin
            File.empty?(args.first.to_s)
          rescue File::NotFoundError
            Logger.report_error("Failed to read from file", "File '#{args.first.to_s}' could not be found", t)
          end
        end
      end

      # Checks whether or not the given path exists and is a directory
      class Directory < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : Bool
          t = token("File->directory?")
          TypeChecker.assert("string", args.first, t)
          File.directory?(args.first.to_s)
        end
      end

      # Checks whether or not the given path exists
      class Exists < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : Bool
          t = token("File->exists?")
          TypeChecker.assert("string", args.first, t)
          File.exists?(args.first.to_s)
        end
      end

      # Deletes the given file
      class Delete < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : Nil
          t = token("File->delete")
          TypeChecker.assert("string", args.first, t)
          begin
            File.delete(args.first.to_s)
          rescue File::NotFoundError
            Logger.report_error("Failed to delete file", "File '#{args.first.to_s}' could not be found", t)
          end
        end
      end

      # Appends to the end of the given file
      class Append < IFunction
        def arity : Range(UInt32, UInt32)
          2.to_u .. 2.to_u
        end

        def call(args : Array(ValueType)) : Nil
          t = token("File->append")
          TypeChecker.assert("string", args.first, t)
          TypeChecker.assert("string|char", args[1], t)
          begin
            File.write(args.first.to_s, args[1].to_s, mode: "a")
          rescue File::NotFoundError
            Logger.report_error("Failed to append to file", "File '#{args.first.to_s}' could not be found", t)
          end
        end
      end

      # Overwrites all contents of the given file
      class Write < IFunction
        def arity : Range(UInt32, UInt32)
          2.to_u .. 2.to_u
        end

        def call(args : Array(ValueType)) : Nil
          t = token("File->write")
          TypeChecker.assert("string", args.first, t)
          TypeChecker.assert("string", args[1], t)
          begin
            File.write(args.first.to_s, args[1].to_s)
          rescue File::NotFoundError
            Logger.report_error("Failed to write to file", "File '#{args.first.to_s}' could not be found", t)
          end
        end
      end

      # Reads the contents of a file
      class Read < IFunction
        def arity : Range(UInt32, UInt32)
          1.to_u .. 1.to_u
        end

        def call(args : Array(ValueType)) : String
          t = token("File->read")
          TypeChecker.assert("string", args.first, t)
          begin
            File.read(args.first.to_s)
          rescue File::NotFoundError
            Logger.report_error("Failed to read from file", "File '#{args.first.to_s}' could not be found", t)
          end
        end
      end
    end
  end
end
