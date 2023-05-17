module Cosmo::AST::Expression
  include Cosmo::AST

  module Visitor(R)
    abstract def visit_type_alias_expr(expr : TypeAlias) : R
    abstract def visit_fn_call_expr(expr : FunctionCall) : R
    abstract def visit_var_declaration_expr(expr : VarDeclaration) : R
    abstract def visit_var_assignment_expr(expr : VarAssignment) : R
    abstract def visit_var_expr(expr : Var) : R
    abstract def visit_binary_op_expr(expr : BinaryOp) : R
    abstract def visit_unary_op_expr(expr : UnaryOp) : R
    abstract def visit_literal_expr(expr : Literal) : R
    abstract def visit_range_literal_expr(expr : RangeLiteral) : R
    abstract def visit_table_literal_expr(expr : TableLiteral) : R
    abstract def visit_vector_literal_expr(expr : VectorLiteral) : R
  end

  abstract class Base < Node
    abstract def accept(visitor : Visitor(R)) forall R
  end

  class TernaryOp < Base
    getter condition : Expression::Base
    getter operator : Token
    getter then : Expression::Base
    getter else : Expression::Base

    def initialize(@condition, @operator, @then, @else)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_ternary_op_expr(self)
    end

    def token : Token
      @operator
    end

    def to_s(indent : Int = 0)
      "Ternary<\n" +
      "  #{TAB * indent}left: #{@condition.to_s(indent + 1)},\n" +
      "  #{TAB * indent}then: #{@then.to_s(indent + 1)}\n" +
      "  #{TAB * indent}else: #{@else.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class PropertyAssignment < Base
    getter object : Access | Index
    getter value : Expression::Base | ValueType

    def initialize(@object, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_property_assignment_expr(self)
    end

    def token : Token
      @object.token
    end

    def to_s(indent : Int = 0)
      if value.is_a?(Expression::Base)
        value_s = @value.as(Expression::Base).to_s(indent + 1)
      else
        value_s = @value.to_s
      end
      "PropertyAssignment<object: #{@object.to_s(indent + 1)}, value: #{value_s}>"
    end
  end

  class Access < Base
    getter object : Expression::Base
    getter key : Token

    def initialize(@object, @key)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_access_expr(self)
    end

    def token : Token
      @object.token
    end

    def to_s(indent : Int = 0)
      "Access<\n" +
      "  #{TAB * indent}object: #{@object.to_s(indent + 1)},\n" +
      "  #{TAB * indent}key: #{@key.to_s}\n" +
      "#{TAB * indent}>"
    end
  end

  class Index < Base
    getter object : Expression::Base
    getter key : Expression::Base

    def initialize(@object, @key)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_index_expr(self)
    end

    def token : Token
      @object.token
    end

    def to_s(indent : Int = 0)
      "Index<\n" +
      "  #{TAB * indent}object: #{@object.to_s(indent + 1)},\n" +
      "  #{TAB * indent}key: #{@key.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

    def to_s(indent : Int = 0)
      "TypeRef<\"#{@name.value.to_s}\">"
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

    def to_s(indent : Int = 0)
      "TypeAlias<\n" +
      "  #{TAB * indent}#{@var.token.value.to_s}: #{@value.nil? ? "none" : @value.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class FunctionCall < Base
    getter callee : Expression::Base
    getter arguments : Array(Expression::Base)

    def initialize(@callee, @arguments)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_fn_call_expr(self)
    end

    def token : Token
      @callee.token
    end

    def to_s(indent : Int = 0)
      "FunctionCall<\n" +
      "  #{TAB * indent}var: #{@callee.to_s(indent + 1)},\n" +
      "  #{TAB * indent}arguments: [\n" +
      "    #{TAB * indent}#{@arguments.map(&.to_s(indent + 2)).join(",\n#{TAB * (indent + 2)}")}\n" +
      "  #{TAB * indent}]\n" +
      "#{TAB * indent}>"
    end
  end

  class Parameter < Base
    getter typedef : Token
    getter identifier : Token
    getter default_value : Expression::Base?

    def initialize(@typedef, @identifier, @default_value = NoneLiteral.new(nil, identifier))
    end

    def accept(visitor : Visitor(R)) : R forall R
    end

    def token : Token
      @identifier
    end

    def to_s(indent : Int = 0)
      "Parameter<\n" +
      "  #{TAB * indent}typedef: #{@typedef.value},\n" +
      "  #{TAB * indent}identifier: #{@identifier.value.to_s},\n" +
      "  #{TAB * indent}value: #{@default_value.nil? ? "none" : @default_value.not_nil!.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

    def to_s(indent : Int = 0)
      "CompoundAssignment<\n"
      "  #{TAB * indent}name: #{@name.value},\n"
      "  #{TAB * indent}operator: #{@operator.to_s},\n"
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n"
      "#{TAB * indent}>"
    end
  end

  class VarDeclaration < Base
    getter typedef : Token
    getter var : Var
    getter value : Expression::Base
    getter? constant : Bool

    def initialize(@typedef, @var, @value, @constant)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_declaration_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s(indent : Int = 0)
      "VarDeclaration<\n" +
      "  #{TAB * indent}typedef: #{@typedef.value},\n" +
      "  #{TAB * indent}var: #{@var.token.value.to_s},\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class VarAssignment < Base
    getter var : Var
    getter value : Expression::Base

    def initialize(@var, @value)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_assignment_expr(self)
    end

    def token : Token
      @var.token
    end

    def to_s(indent : Int = 0)
      "VarAssignment<\n" +
      "  #{TAB * indent}var: #{@var.token.value.to_s},\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class Var < Base
    getter token : Token

    def initialize(@token)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_var_expr(self)
    end

    def to_s(indent : Int = 0)
      "Var<\"#{@token.value.to_s}\">"
    end
  end

  class BinaryOp < Base
    getter left : Expression::Base
    getter operator : Token
    getter right : Expression::Base

    def initialize(@left, @operator, @right)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_binary_op_expr(self)
    end

    def token : Token
      @left.token
    end

    def to_s(indent : Int = 0)
      "Binary<\n" +
      "  #{TAB * indent}left: #{@left.to_s(indent + 1)},\n" +
      "  #{TAB * indent}operator: #{@operator.to_s},\n" +
      "  #{TAB * indent}right: #{@right.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class UnaryOp < Base
    getter operator : Token
    getter operand : Expression::Base

    def initialize(@operator, @operand)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_unary_op_expr(self)
    end

    def token : Token
      @operator
    end

    def to_s(indent : Int = 0)
      "Unary<\n" +
      "  #{TAB * indent}operator: #{@operator.to_s},\n" +
      "  #{TAB * indent}operand: #{@operand.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
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

  class RangeLiteral < Base
    getter from : Expression::Base
    getter to : Expression::Base

    def initialize(@from, @to)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_range_literal_expr(self)
    end

    def token : Token
      @from.token
    end

    def to_s(indent : Int = 0)
      "RangeLiteral<\n" +
      "  #{TAB * indent}from: #{@from.to_s(indent + 1)},\n" +
      "  #{TAB * indent}to: #{@to.to_s(indent + 1)}\n" +
      "#{TAB * indent}>"
    end
  end

  class TableLiteral < Base
    getter token : Token
    getter hashmap : Hash(Base, Base)

    def initialize(@hashmap, @token); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_table_literal_expr(self)
    end

    def to_s(indent : Int = 0)
      s = "Literal<{\n"
      @hashmap.keys.each do |k|
        s += TAB * (indent + 1)
        s += k.to_s(indent + 1)
        s += " -> "
        s += @hashmap[k].to_s(indent + 1)
        s += "\n"
      end
      s + "#{TAB * indent}}>"
    end
  end

  class VectorLiteral < Base
    getter token : Token
    getter values : Array(Base)

    def initialize(@values, @token); end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_vector_literal_expr(self)
    end

    def to_s(indent : Int = 0)
      "Literal<[\n" +
      "  #{TAB * indent}#{@values.map(&.to_s(indent + 2)).join(",\n#{TAB * (indent + 1)}")}\n" +
      "#{TAB * indent}]>"
    end
  end

  class StringLiteral < Literal
    def initialize(@value : String, @token); end
    def to_s(indent : Int = 0)
      "Literal<\"#{@value}\">"
    end
  end

  class CharLiteral < Literal
    def initialize(@value : Char, @token); end
    def to_s(indent : Int = 0)
      "Literal<'#{@value}'>"
    end
  end

  class IntLiteral < Literal
    def initialize(@value : Int64 | Int32 | Int16 | Int8, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end

  class FloatLiteral < Literal
    def initialize(@value : Float64 | Float32 | Float16 | Float8, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end

  class BooleanLiteral < Literal
    def initialize(@value : Bool, @token); end
    def to_s(indent : Int = 0)
      "Literal<#{@value}>"
    end
  end

  class NoneLiteral < Literal
    def initialize(@value : Nil, @token); end
    def to_s(indent : Int = 0)
      "Literal<none>"
    end
  end
end
