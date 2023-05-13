module Cosmo::AST::Statement
  class FunctionDef < Node
    getter identifier : Token
    getter parameters : Array(Expression::Parameter)
    getter body : Block
    getter return_typedef : Token

    def initialize(@identifier, @parameters, @body, @return_typedef)
    end

    def to_s
      "FunctionDef<identifier: #{@var.identifier.value.to_s}, parameters: [#{@parameters.map(&.to_s).join(", ")}], return_typedef: #{@return_typedef.value}, body: #{@body.to_s}>"
    end
  end

  class Block < Node
    getter nodes : Array(Node)

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
    def single_expression? : Node?
      return @nodes.first.single_expression if @nodes.size == 1
      nil
    end

    def to_s
      "Block<nodes: [#{@nodes.map(&.to_s).join(", ")}]>"
    end
  end
end
