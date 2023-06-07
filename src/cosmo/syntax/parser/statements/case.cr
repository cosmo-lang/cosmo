module Cosmo::AST::Statement
  struct When
    getter keyword : Token
    getter conditions : Array(Expression::Base)
    getter block : Base

    def initialize(@keyword, @conditions, @block)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "When<\n" +
      "  #{TAB * indent}conditions: [\n" +
      "    #{TAB * indent}#{@conditions.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}block: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class Case < Base
    getter keyword : Token
    getter value : Expression::Base
    getter comparisons : Array(When)
    getter else : Base?

    def initialize(@keyword, @value, @comparisons, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_case_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Case<\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)},\n" +
      "  #{TAB * indent}comparisons: [\n" +
      "    #{TAB * indent}#{@comparisons.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}else: #{@else.nil? ? "none" : @else.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end
end
