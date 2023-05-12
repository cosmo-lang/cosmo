module Cosmo::AST::Statement
  class ExpressionList
    getter expressions : Array(Node)

    def initialize(@expressions = [] of Node)
    end

    def empty?
      @expressions.empty?
    end

    def [](i : UInt) : Node
      @expressions[i]
    end

    def last : Node
      @expressions.last
    end

    def location : Location
      @location || @expressions.first?.try &.location
    end

    def end_location : Location
      @end_location || @expressions.last?.try &.end_location
    end

    # It yields first node if this holds only one node, or yields `nil`.
    def single_expression? : Node?
      return @expressions.first.single_expression if @expressions.size == 1
      nil
    end
  end
end
