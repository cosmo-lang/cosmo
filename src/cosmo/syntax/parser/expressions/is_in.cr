module Cosmo::AST::Expression
  class IsIn < Base
    # if
    getter value : Base
    # is in
    getter object : Base
    getter? inversed : Bool
    getter keyword : Token

    def initialize(@value, @object, @inversed, @keyword)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_is_in_expr(self)
    end

    def token : Token
      @value.token
    end

    def to_s(indent : Int = 0)
      "IsIn<\n" +
      "  #{TAB * indent}value: #{@value.to_s(indent + 1)},\n" +
      "  #{TAB * indent}object: #{@object.to_s(indent + 1)}\n" +
      "  #{TAB * indent}inversed?: #{@inversed.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
