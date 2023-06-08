module Cosmo::AST::Statement
  class Use < Base
    getter imports : Array(Token)
    getter module_path : Token
    getter keyword : Token
    getter bound_name : Token?

    def initialize(@imports, @module_path, @keyword, @bound_name = nil)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_use_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Use<\n" +
      "  #{TAB * indent}imports: #{@imports.map(&.to_s).to_s}\n" +
      "  #{TAB * indent}module_path: #{@module_path.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
