TAB = "  "

module Cosmo::AST
  enum Visibility
    Public
    Protected
    Private
    Static
  end

  abstract class Node
    property start_location : Location?
    property end_location : Location?
    property visibility = Visibility::Public

    abstract def token : Token

    # It yields itself for any node, but if it's a
    # `Statement::ExpressionList`, then it returns the
    # first node of the `ExpressionList` statement
    def single_expression : Node
      single_expression? || self
    end

    # It yields `nil` always for any regular node.
    # (It is overridden by `ExpressionList` to implement `#single_expression`.)
    def single_expression? : Node?
      nil
    end
  end
end

require "./ast/expression_nodes"
require "./ast/statement_nodes"
