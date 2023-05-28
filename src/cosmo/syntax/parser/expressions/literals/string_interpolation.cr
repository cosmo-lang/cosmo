module Cosmo::AST::Expression
  class StringInterpolation < Base
    getter parts : Array(String | Expression::Base)
    getter token : Token

    def initialize(@parts, @token)
    end

    def accept(visitor : Visitor(R)) : R forall R
      visitor.visit_string_interpolation_expr(self)
    end

    def to_s(indent : Int = 0)
      "StringInterpolation<parts: ["
      "  #{TAB * indent}#{@parts.map{ |p| p.is_a?(String) ? p : p.to_s(indent + 2) }.join(",\n#{TAB * (indent + 1)}")}\n" +
      "#{TAB * indent}]>"
    end
  end
end
