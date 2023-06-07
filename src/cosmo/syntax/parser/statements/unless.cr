module Cosmo::AST::Statement
  class Unless < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter then : Base
    getter else : Base?

    def initialize(@keyword, @condition, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_unless_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Unless<\n" +
      "  #{TAB * indent}condition: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}then: #{@then.to_s(indent + 1)},\n" +
      "  #{TAB * indent}else: #{@else.nil? ? "none" : @else.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
