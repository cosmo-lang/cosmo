module Cosmo::Intrinsic
  # An intrinsic function
  abstract class IFunction < Callable
    def initialize(@interpreter : Interpreter)
    end

    abstract def call(args : Array(ValueType)) : ValueType

    def intrinsic? : Bool
      true
    end

    # Helper function to generate a fake token for logging
    def token(name : String) : Token
      location = Location.new("intrinsic_fn", 0, 0)
      Token.new(name, Syntax::Identifier, name, location)
    end

    def to_s : String
      "<intrinsic_fn: 0x#{self.object_id.to_s(16)}>"
    end
  end

  # An intrinsic library
  abstract class Lib
    def initialize(@i : Interpreter)
    end

    # Helper function to generate a fake token for logging
    def token(name : String) : Token
      location = Location.new("intrinsic_lib", 0, 0)
      Token.new(name, Syntax::Identifier, name, location)
    end

    # Injects all members into the current scope
    abstract def inject : Nil
  end
end

require "./intrinsic/global/puts"
require "./intrinsic/global/gets"
require "./intrinsic/global/eval"
require "./intrinsic/global/recursion_depth"
require "./intrinsic/number"
require "./intrinsic/string"
require "./intrinsic/char"
require "./intrinsic/vector"
require "./intrinsic/table"
require "./intrinsic/range"
require "./intrinsic/lib/math"
require "./intrinsic/lib/http"
require "./intrinsic/lib/json"
require "./intrinsic/lib/system"
require "./intrinsic/lib/socket"
require "./intrinsic/lib/file"
require "./intrinsic/lib/webhook"
