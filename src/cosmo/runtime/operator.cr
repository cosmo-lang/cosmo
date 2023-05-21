module Cosmo::Operator
  private alias ExprType = Expression::BinaryOp | Expression::CompoundAssignment

  private abstract class Base
    def initialize(@interpreter : Interpreter)
    end
    abstract def apply(expr : E) : ValueType forall E
  end

  class Plus < Base
    def apply(expr : Expression::BinaryOp, op : String = "+") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      if left.is_a?(Float)
        return left + right if right.is_a?(Float)
        return left + right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left + right if right.is_a?(Int)
        return left.to_f + right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(String)
        return left + right if right.is_a?(String)
        return left + right.to_s if right.is_a?(Char)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Char)
        return left.to_s + right.to_s if right.is_a?(Char)
        return left.to_s + right if right.is_a?(String)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Minus < Base
    def apply(expr : Expression::BinaryOp, op : String = "-") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      if left.is_a?(Float)
        return left - right if right.is_a?(Float)
        return left - right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left - right if right.is_a?(Int)
        return left.to_f - right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Mul < Base
    def apply(expr : Expression::BinaryOp, op : String = "*") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      if left.is_a?(Float)
        return left * right if right.is_a?(Float)
        return left * right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left * right if right.is_a?(Int)
        return left.to_f * right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Div < Base
    def apply(expr : Expression::BinaryOp, op : String = "/") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      if left.is_a?(Float)
        return left / right if right.is_a?(Float)
        return left / right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left / right if right.is_a?(Int)
        return left.to_f / right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Pow < Base
    def apply(expr : Expression::BinaryOp, op : String = "^") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      if left.is_a?(Float)
        return left ** right if right.is_a?(Float)
        return left ** right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left ** right if right.is_a?(Int)
        return left.to_f ** right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Mod < Base
    def apply(expr : Expression::BinaryOp, op : String = "%") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '%'
      if left.is_a?(Float)
        return left % right if right.is_a?(Float)
        return left % right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left % right if right.is_a?(Int)
        return left.to_f % right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class LT < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '<'
      if left.is_a?(Float)
        return left < right if right.is_a?(Float)
        return left < right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left < right if right.is_a?(Int)
        return left.to_f < right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class LTE < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "<="
      if left.is_a?(Float)
        return left <= right if right.is_a?(Float)
        return left <= right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left <= right if right.is_a?(Int)
        return left.to_f <= right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class GT < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '>'
      if left.is_a?(Float)
        return left > right if right.is_a?(Float)
        return left > right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left > right if right.is_a?(Int)
        return left.to_f > right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class GTE < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = ">="
      if left.is_a?(Float)
        return left >= right if right.is_a?(Float)
        return left >= right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      elsif left.is_a?(Int)
        return left >= right if right.is_a?(Int)
        return left.to_f >= right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
    end
  end

  class Bnot < Base
    def apply(expr : Expression::UnaryOp) : ValueType
      operand = @interpreter.evaluate(expr.operand)
      op = "~"
      return ~operand if operand.is_a?(Int)
      Logger.report_error("Invalid '#{op}' operand type", operand.class.to_s, expr.operator)
    end
  end

  class Bxor < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "~"
      if left.is_a?(Int)
        return left ^ right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
    end
  end

  class Bor < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "|"
      if left.is_a?(Int)
        return left | right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
    end
  end

  class Band < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "&"
      if left.is_a?(Int)
        return left & right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
    end
  end

  class Bshr < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = ">>"
      if left.is_a?(Int)
        return left >> right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
    end
  end

  class Bshl < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "<<"
      if left.is_a?(Int)
        return left << right if right.is_a?(Int)
      elsif left.is_a?(Array)
        left = @interpreter.add_object_value(expr.operator, left, left.size, right)
        return @interpreter.scope.assign(expr.token, left)
      else
        Logger.report_error("Invalid '#{op}' operand type", left.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", right.class.to_s, expr.operator)
    end
  end

  class PlusAssign < Base
    def apply(expr : Expression::CompoundAssignment | Expression::UnaryOp, op_lexeme : String = "+=") : ValueType
      left = expr.is_a?(Expression::UnaryOp) ? expr.operand : expr.name
      literal = Expression::IntLiteral.new(1, expr.token)
      binary = Expression::BinaryOp.new(left, expr.token, expr.is_a?(Expression::UnaryOp) ? literal : expr.value)
      op = Plus.new(@interpreter)
      result = op.apply(binary, op_lexeme)
      @interpreter.scope.assign(left.token, result)
    end
  end

  class MinusAssign < Base
    def apply(expr : Expression::CompoundAssignment | Expression::UnaryOp, op_lexeme : String = "-=") : ValueType
      left = expr.is_a?(Expression::UnaryOp) ? expr.operand : expr.name
      literal = Expression::IntLiteral.new(1, expr.token)
      binary = Expression::BinaryOp.new(left, expr.token, expr.is_a?(Expression::UnaryOp) ? literal : expr.value)
      op = Minus.new(@interpreter)
      result = op.apply(binary, op_lexeme)
      @interpreter.scope.assign(left.token, result)
    end
  end

  class MulAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      op = Mul.new(@interpreter)
      result = op.apply(binary, "*=")
      @interpreter.scope.assign(expr.name.token, result)
    end
  end

  class DivAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      op = Div.new(@interpreter)
      result = op.apply(binary, "/=")
      @interpreter.scope.assign(expr.name.token, result)
    end
  end

  class PowAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      op = Pow.new(@interpreter)
      result = op.apply(binary, "^=")
      @interpreter.scope.assign(expr.name.token, result)
    end
  end

  class ModAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      op = Mod.new(@interpreter)
      result = op.apply(binary, "%=")
      @interpreter.scope.assign(expr.name.token, result)
    end
  end

  class AndAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      expr.token.type = Syntax::ColonAmpersand
      expr.token.lexeme = ":&"

      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment.object)
      value = @interpreter.evaluate(expr.value)
      @interpreter.scope.assign(expr.name.token, var_value && value)
    end
  end

  class OrAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      expr.token.type = Syntax::ColonPipe
      expr.token.lexeme = ":|"

      binary = Expression::BinaryOp.new(expr.name, expr.token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment.object)
      value = @interpreter.evaluate(expr.value)
      @interpreter.scope.assign(expr.name.token, var_value || value)
    end
  end
end
