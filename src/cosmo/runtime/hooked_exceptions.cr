module Cosmo::HookedExceptions
  private abstract class HookedException < Exception
    def initialize(token : Token, message : String)
      super "[#{token.location.line}:#{token.location.position + 1}] #{message}"
    end
  end

  class Return < HookedException
    getter value : ValueType

    def initialize(@value, token : Token)
      super token, "Invalid return: A return statement can only be used within a function body"
    end
  end

  class Break < HookedException
    def initialize(token : Token)
      super token, "Invalid break: 'break' can only be used within a loop"
    end
  end

  class Next < HookedException
    def initialize(token : Token)
      super token, "Invalid next: 'next' can only be used within a loop"
    end
  end
end
