module Cosmo::AST::Expression
  include Cosmo::AST

  abstract class Literal < Node
    getter value : LiteralType
    def initialize(@value); end
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

  class NoneLiteral < Literal
    getter value = nil
    def to_s
      "Literal<none>"
    end
  end

  class BinaryOp < Node
    getter left : Node
    getter operator : Token
    getter right : Node

    def initialize(@left, @operator, @right)
    end

    def to_s
      "Binary<left: #{@left}, operator: #{@operator.type}, right: #{@right}>"
    end
  end

  class UnaryOp < Node
    getter operator : Token
    getter operand : Node

    def initialize(@operator, @operand)
    end

    def to_s
      "Unary<operator: #{@operator.type}, operand: #{@operand}>"
    end
  end
end
