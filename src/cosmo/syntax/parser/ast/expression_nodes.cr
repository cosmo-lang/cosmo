module Cosmo::AST::Expression
  include Cosmo::AST

  module Visitor(R)
    abstract def visit_fn_call_expr(expr : FunctionCall) : R
    abstract def visit_var_declaration_expr(expr : VarDeclaration) : R
    abstract def visit_var_assignment_expr(expr : VarAssignment) : R
    abstract def visit_var_expr(expr : Var) : R
    abstract def visit_binary_op_expr(expr : BinaryOp) : R
    abstract def visit_unary_op_expr(expr : UnaryOp) : R
    abstract def visit_literal_expr(expr : Literal) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end

  class FunctionCall < Base
    getter var : Var
    getter arguments : Array(Node)

    def initialize(@var, @arguments)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_call_expr(self)
    end

    def to_s
      "FunctionCall<var: #{@var.to_s}, argu: [#{@arguments.map(&.to_s).join(", ")}]>"
    end
  end

  class Parameter < Base
    getter typedef : Token
    getter identifier : Token
    getter default_value : Node?

    def initialize(@typedef, @identifier, @default_value = NoneLiteral.new)
    end

    def accept(visitor : Visitor(R)) : R forall R

    end

    def to_s
      "Parameter<typedef: #{@typedef.value}, identifier: #{@identifier.value.to_s}, value: #{@default_value.nil? ? "none" : @default_value.to_s}>"
    end
  end

  class VarDeclaration < Base
    getter typedef : Token
    getter var : Var
    getter value : Node

    def initialize(@typedef, @var, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_declaration_expr(self)
    end

    def to_s
      "VarDeclaration<typedef: #{@typedef.value}, var: #{@var.token.value.to_s}, value: #{@value.to_s}>"
    end
  end

  class VarAssignment < Base
    getter var : Var
    getter value : Node

    def initialize(@var, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_assignment_expr(self)
    end

    def to_s
      "VarAssignment<var: #{@var.token.value.to_s}, value: #{@value.to_s}>"
    end
  end

  class Var < Base
    getter token : Token

    def initialize(@token)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_expr(self)
    end

    def to_s
      "Var<token: #{@token.to_s}>"
    end
  end

  class BinaryOp < Base
    getter left : Node
    getter operator : Token
    getter right : Node

    def initialize(@left, @operator, @right)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_binary_op_expr(self)
    end

    def to_s
      "Binary<left: #{@left.to_s}, operator: #{@operator}, right: #{@right.to_s}>"
    end
  end

  class UnaryOp < Base
    getter operator : Token
    getter operand : Node

    def initialize(@operator, @operand)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_unary_op_expr(self)
    end

    def to_s
      "Unary<operator: #{@operator}, operand: #{@operand.to_s}>"
    end
  end

  abstract class Literal < Base
    getter value : LiteralType
    def initialize(@value); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_literal_expr(self)
    end
  end

  class StringLiteral < Literal
    def initialize(@value : String); end
    def to_s
      "Literal<\"#{value}\">"
    end
  end

  class CharLiteral < Literal
    def initialize(@value : Char); end
    def to_s
      "Literal<'#{value}'>"
    end
  end

  class IntLiteral < Literal
    def initialize(@value : Int64 | Int32 | Int16 | Int8); end
    def to_s
      "Literal<#{value}>"
    end
  end

  class FloatLiteral < Literal
    def initialize(@value : Float64 | Float32 | Float16 | Float8); end
    def to_s
      "Literal<#{value}>"
    end
  end

  class BooleanLiteral < Literal
    def initialize(@value : Bool); end
    def to_s
      "Literal<#{value}>"
    end
  end

  class NoneLiteral < Literal
    def initialize
      super nil
    end
    def to_s
      "Literal<none>"
    end
  end
end
