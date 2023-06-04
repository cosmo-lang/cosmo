module Cosmo::AST::Statement
  class TryCatch < Base
    getter try_keyword : Token
    getter catch_keyword : Token
    getter finally_keyword : Token?
    getter try_block : Base
    getter catch_block : Base
    getter finally_block : Base?
    getter caught_exception : Expression::VarDeclaration

    def initialize(
      @try_keyword,
      @catch_keyword,
      @finally_keyword,
      @try_block,
      @catch_block,
      @finally_block,
      @caught_exception
    )
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_try_catch_stmt(self)
    end

    def token : Token
      @try_keyword
    end

    def to_s(indent : Int = 0)
      "TryCatch<\n" +
      "  #{TAB * indent}try_block: #{@try_block.to_s(indent + 2)}\n" +
      "  #{TAB * indent}catch_block: #{@catch_block.to_s(indent + 2)}\n" +
      "  #{TAB * indent}finally_block: #{@finally_block.nil? ? "none" : @finally_block.not_nil!.to_s(indent + 2)}\n" +
      "  #{TAB * indent}caught_exception: #{@caught_exception.to_s(indent + 2)}\n" +
      "#{TAB * indent}>"
    end
  end
end
