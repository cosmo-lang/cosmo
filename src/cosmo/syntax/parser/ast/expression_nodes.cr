module Cosmo::AST::Expression
  include Cosmo::AST

  module Visitor(R)
    abstract def visit_vector_literal_expr(expr : VectorLiteral) : R
    abstract def visit_type_alias_expr(expr : TypeAlias) : R
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

  class Index < Base
    getter ref : Var
    getter key : Expression::Base

    def initialize(@ref, @key)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_index_expr(self)
    end

    def token : Token
      @ref.token
    end

    def to_s
      "Index<ref: #{@ref.to_s}, key: #{@key.to_s}>"
    end
  end

  class TypeRef < Base
    getter name : Token

    def initialize(@name)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_type_ref_expr(self)
    end

    def token : Token
      @name
    end

    def to_s
      "TypeRef<\"#{@name}\">"
    end
  end

  class TypeAlias < Base
    getter type_token : Token
    getter var : Var
    getter value : Node?

    def initialize(@type_token, @var, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_type_alias_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s
      "TypeAlias<#{@var.token.value.to_s}: #{@value.to_s}>"
    end
  end

  class FunctionCall < Base
    getter var : Var
    getter arguments : Array(Node)

    def initialize(@var, @arguments)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_call_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s
      "FunctionCall<var: #{@var.to_s}, arguments: [#{@arguments.map(&.to_s).join(", ")}]>"
    end
  end

  class Parameter < Base
    getter typedef : Token
    getter identifier : Token
    getter default_value : Node?

    def initialize(@typedef, @identifier, @default_value = NoneLiteral.new(nil, identifier))
    end

    def accept(visitor : Visitor(R)) : R forall R
    end

    def token : Token
      @identifier
    end

    def to_s
      "Parameter<typedef: #{@typedef.value}, identifier: #{@identifier.value.to_s}, value: #{@default_value.nil? ? "none" : @default_value.to_s}>"
    end
  end

  class CompoundAssignment < Base
    getter name : Token
    getter operator : Token
    getter value : Node

    def initialize(@name, @operator, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_compound_assignment_expr(self)
    end

    def token : Token
      @name
    end

    def to_s
      "CompoundAssignment<name: #{@name.value}, operator: #{@operator.to_s}, value: #{@value.to_s}>"
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

    def token : Token
      @var.token
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

    def token : Token
      @var.token
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

    def token : Token
      @left.token
    end

    def to_s
      "Binary<left: #{@left.to_s}, operator: #{@operator.to_s}, right: #{@right.to_s}>"
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

    def token : Token
      @operator
    end

    def to_s
      "Unary<operator: #{@operator.to_s}, operand: #{@operand.to_s}>"
    end
  end

  abstract class Literal < Base
    getter token : Token
    getter value : LiteralType

    def initialize(@value, @token); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_literal_expr(self)
    end
  end

  class VectorLiteral < Base
    getter token : Token
    getter values : Array(Base)

    def initialize(@values, @token); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_vector_literal_expr(self)
    end

    def to_s
      "Literal<[#{@values.map(&.to_s).join(", ")}]>"
    end
  end

  class StringLiteral < Literal
    def initialize(@value : String, @token); end
    def to_s
      "Literal<\"#{@value}\">"
    end
  end

  class CharLiteral < Literal
    def initialize(@value : Char, @token); end
    def to_s
      "Literal<'#{@value}'>"
    end
  end

  class IntLiteral < Literal
    def initialize(@value : Int64 | Int32 | Int16 | Int8, @token); end
    def to_s
      "Literal<#{@value}>"
    end
  end

  class FloatLiteral < Literal
    def initialize(@value : Float64 | Float32 | Float16 | Float8, @token); end
    def to_s
      "Literal<#{@value}>"
    end
  end

  class BooleanLiteral < Literal
    def initialize(@value : Bool, @token); end
    def to_s
      "Literal<#{@value}>"
    end
  end

  class NoneLiteral < Literal
    def initialize(@value : Nil, @token); end
    def to_s
      "Literal<none>"
    end
  end
end
