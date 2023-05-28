module Cosmo::AST::Statement
  class Block < Base
    getter nodes : Array(Base)

    def initialize(@nodes = [] of Node)
    end

    def empty?
      @nodes.empty?
    end

    def [](i : UInt) : Node
      @nodes[i]
    end

    def first : Node
      @nodes.first
    end

    def last : Node
      @nodes.last
    end

    def location : Location
      @location || @nodes.first?.try &.location
    end

    def end_location : Location
      @end_location || @nodes.last?.try &.end_location
    end

    # It yields first node if this holds only one node, or yields `nil`.
    def single_expression? : Expression::Base?
      if @nodes.size == 1
        expr = @nodes.first.single_expression
        if expr.is_a?(Statement::SingleExpression)
          expr.expression
        else
          expr.as Expression::Base
        end
      else
        nil
      end
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_block_stmt(self)
    end

    def token : Token
      @nodes.empty? ? Token.new("none", Syntax::None, nil, Location.new("", 0, 0)) : @nodes.first.token
    end

    def to_s(indent : Int = 0)
      "Block<nodes: [\n" +
      "  #{TAB * indent}#{@nodes.map(&.to_s(indent + 1)).join(",\n#{TAB * (indent + 1)}")}\n" +
      "#{TAB * indent}]>"
    end
  end
end
