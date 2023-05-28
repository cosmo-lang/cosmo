module Cosmo::AST::Expression
  class Index < Base
    getter object : Base
    getter key : Base
    getter nullable : Bool

    def initialize(@object, @key, @nullable)
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
end
