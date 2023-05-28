module Cosmo::AST::Expression
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
end
