module Cosmo::AST::Statement
  module Visitor(R)
    abstract def visit_return_stmt(stmt : Return) : R
    abstract def visit_fn_def_stmt(stmt : FunctionDef) : R
    abstract def visit_single_expr_stmt(stmt : SingleExpression) : R
    abstract def visit_block_stmt(stmt : Block) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end

  class While < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter block : Block

    def initialize(@keyword, @condition, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_while_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s
      "While<condition: #{@condition.to_s}, do: #{@block.to_s}>"
    end
  end

  class Until < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter block : Block

    def initialize(@keyword, @condition, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_until_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s
      "Until<condition: #{@condition.to_s}, do: #{@block.to_s}>"
    end
  end

  class If < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter then : Block
    getter else : (If | Block)?

    def initialize(@keyword, @condition, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_if_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s
      "If<condition: #{@condition.to_s}, then: #{@then.to_s}, else: #{@else.to_s}>"
    end
  end

  class Unless < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter then : Block
    getter else : (Unless | Block)?

    def initialize(@keyword, @condition, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_unless_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s
      "Unless<condition: #{@condition.to_s}, then: #{@then.to_s}, else: #{@else.to_s}>"
    end
  end

  class Return < Base
    getter value : Expression::Base
    getter keyword : Token

    def initialize(@value, @keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_return_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s
      "Return<value: #{@value.to_s}>"
    end
  end

  class FunctionDef < Base
    getter identifier : Token
    getter parameters : Array(Expression::Parameter)
    getter body : Block
    getter return_typedef : Token

    def initialize(@identifier, @parameters, @body, @return_typedef)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_def_stmt(self)
    end

    def token : Token
      @identifier
    end

    def to_s
      "FunctionDef<identifier: #{@identifier.value.to_s}, parameters: [#{@parameters.map(&.to_s).join(", ")}], return_typedef: #{@return_typedef.value}, body: #{@body.to_s}>"
    end
  end

  class SingleExpression < Base
    getter expression : Expression::Base

    def initialize(@expression)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_single_expr_stmt(self)
    end

    def token : Token
      @expression.token
    end

    def to_s
      "SingleExpression<expression: #{@expression.to_s}>"
    end
  end

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

    def to_s
      "Block<nodes: [#{@nodes.map(&.to_s).join(", ")}]>"
    end
  end
end
