module AST
  enum Visibility
    Public
    Protected
    Private
  end

  abstract class Node
    getter start_location : Location?
    getter end_location : Location?
    property visibility : Visibility::Public

    # It yields itself for any node, but if it's a
    # `Statements::ExpressionList`, then it returns the
    # first node of the `ExpressionList` statement
    def single_expression
      single_expression? || self
    end

    # It yields `nil` always for any regular node.
    # (It is overridden by `ExpressionList` to implement `#single_expression`.)
    def single_expression?
      nil
    end
  end
end
