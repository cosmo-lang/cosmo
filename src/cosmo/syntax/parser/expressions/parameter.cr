module Cosmo::AST::Expression
  class Parameter < Base
    getter typedef : Token
    getter identifier : Token
    getter? const : Bool
    getter default_value : Base?
    getter? spread : Bool

    def initialize(@typedef, @identifier, @const, @spread, @default_value = NoneLiteral.new(nil, identifier))
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
end
