module Cosmo::AST::Statement
  module Visitor(R)
    abstract def visit_every_stmt(stmt : Every) : R
    abstract def visit_while_stmt(stmt : While) : R
    abstract def visit_until_stmt(stmt : Until) : R
    abstract def visit_if_stmt(stmt : If) : R
    abstract def visit_unless_stmt(stmt : Unless) : R
    abstract def visit_return_stmt(stmt : Return) : R
    abstract def visit_fn_def_stmt(stmt : FunctionDef) : R
    abstract def visit_single_expr_stmt(stmt : SingleExpression) : R
    abstract def visit_block_stmt(stmt : Block) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end

  class Throw < Base
    getter err : Expression::Base
    getter keyword : Token

    def initialize(@err, @keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_throw_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Throw<\n" +
      "  #{TAB * indent}err: #{@err.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class Next < Base
    getter keyword : Token

    def initialize(@keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_next_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Next"
    end
  end

  class Break < Base
    getter keyword : Token

    def initialize(@keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_break_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Break"
    end
  end

  class Every < Base
    getter keyword : Token
    getter var : Expression::VarDeclaration
    getter enumerable : Expression::Base
    getter block : Base

    def initialize(@keyword, @var, @enumerable, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_every_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Every<\n" +
      "  #{TAB * indent}var: #{@var.to_s(indent + 1)},\n" +
      "  #{TAB * indent}in: #{@enumerable.to_s(indent + 1)}\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class While < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter block : Base

    def initialize(@keyword, @condition, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_while_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "While<\n" +
      "  #{TAB * indent}condition: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class Until < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter block : Base

    def initialize(@keyword, @condition, @block)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_until_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "Until<\n" +
      "  #{TAB * indent}condition: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}do: #{@block.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class If < Base
    getter keyword : Token
    getter condition : Expression::Base
    getter then : Base
    getter else : Base?

    def initialize(@keyword, @condition, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_if_stmt(self)
    end

    def token : Token
      @keyword
    end

    def to_s(indent : Int = 0)
      "If<\n" +
      "  #{TAB * indent}condition: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}then: #{@then.to_s(indent + 1)},\n" +
      "  #{TAB * indent}else: #{@else.nil? ? "none" : @else.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

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

    def to_s(indent : Int = 0)
      "Return<\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

    def to_s(indent : Int = 0)
      "FunctionDef<\n" +
      "  #{TAB * indent}identifier: #{@identifier.value.to_s},\n" +
      "  #{TAB * indent}parameters: [\n" +
      "    #{TAB * indent}#{@parameters.map(&.to_s(indent + 2).as String).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}],\n" +
      "  #{TAB * indent}return_typedef: #{@return_typedef.value},\n" +
      "  #{TAB * indent}body: #{@body.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

    def to_s(indent : Int = 0)
      "SingleExpression<\n" +
      "  #{TAB * indent}expression: #{@expression.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

    def to_s(indent : Int = 0)
      "Block<nodes: [\n" +
      "  #{TAB * indent}#{@nodes.map(&.to_s(indent + 1)).join(",\n#{TAB * (indent + 1)}")}\n" +
      "#{TAB * indent}]>"
    end
  end
end
