module AST::Expression
  abstract class Literal::Base < Node
    getter value : LiteralType
    def initialize(@value); end
  end

  class Literal::String < Literal::Base
    def initialize(@value : String); end
    def to_s
      "\"#{value}\""
    end
  end

  class Literal::Char < Literal::Base
    def initialize(@value : Char); end
    def to_s
      "'#{value}'"
    end
  end

  class Literal::Int < Literal::Base
    def initialize(@value : Int); end
    def to_s
      "#{value}"
    end
  end

  class Literal::Float < Literal::Base
    def initialize(@value : Float); end
    def to_s
      "#{value}"
    end
  end

  class Literal::None < Literal::Base
    getter value = nil
    def to_s
      "none"
    end
  end

  class BinaryOp < Node
    getter left : Node
    getter operator : Syntax
    getter right : Node

    def initialize(@left, @operator, @right)
    end

    def to_s
      "Binary<left: #{@left}, operator: #{@operator.type}, right: #{@right}>"
    end
  end

  class UnaryOp < Node
    getter operator : Syntax
    getter operand : Node

    def initialize(@operator, @operand)
    end

    def to_s
      "Unary<operator: #{@operator.type}, operand: #{@operand}>"
    end
  end
end
