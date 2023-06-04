module Cosmo::AST::Expression
  private PROP_ACCESS = "::"
  class Access < Base
    getter object : Base
    getter key : Token
    getter? nullable : Bool

    def initialize(@object, @key, @nullable = false)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_access_expr(self)
    end

    def token : Token
      @object.token
    end

    def full_path : String
      path = ""
      if @object.is_a?(Access)
        path += @object.as(Access).full_path
      else
        path += @object.token.lexeme + PROP_ACCESS
      end
      path = path.rchop(PROP_ACCESS) + "->"
      path += @key.lexeme
    end

    def to_s(indent : Int = 0)
      "Access<\n" +
      "  #{TAB * indent}object: #{@object.to_s(indent + 1)},\n" +
      "  #{TAB * indent}key: #{@key.to_s}\n" +
      "  #{TAB * indent}nullable?: #{@nullable.to_s}\n" +
      "#{TAB * indent}>"
    end
  end
end
