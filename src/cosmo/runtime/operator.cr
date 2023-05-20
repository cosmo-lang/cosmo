module Cosmo::Operator
  private alias ExprType = Expression::BinaryOp | Expression::CompoundAssignment

  private abstract class Base
    def initialize(@interpreter : Interpreter)
    end
    abstract def apply(expr : E) : ValueType forall E
  end

  class Plus < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '+'
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
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '-'
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
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '*'
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
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '/'
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
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '^'
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
    def apply(expr : Expression::BinaryOp) : ValueType
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
    def apply(expr : Expression::CompoundAssignment | Expression::UnaryOp, op : String = "+=") : ValueType
      name_token = expr.is_a?(Expression::CompoundAssignment) ? expr.name : expr.operand.token
      var = @interpreter.scope.lookup(name_token)
      value = expr.is_a?(Expression::CompoundAssignment) ? @interpreter.evaluate(expr.value) : 1
      if var.is_a?(Float)
        return @interpreter.scope.assign(name_token, var + value) if value.is_a?(Float)
        return @interpreter.scope.assign(name_token, var + value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(name_token, var + value) if value.is_a?(Int)
        return @interpreter.scope.assign(name_token, var.to_f + value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(String)
        return @interpreter.scope.assign(name_token, var + value) if value.is_a?(String)
        return @interpreter.scope.assign(name_token, var + value.to_s) if value.is_a?(Char)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Char)
        return @interpreter.scope.assign(name_token, var.to_s + value.to_s) if value.is_a?(Char)
        return @interpreter.scope.assign(name_token, var.to_s + value) if value.is_a?(String)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class MinusAssign < Base
    def apply(expr : Expression::CompoundAssignment | Expression::UnaryOp, op : String = "-=") : ValueType
      name_token = expr.is_a?(Expression::CompoundAssignment) ? expr.name : expr.operand.token
      var = @interpreter.scope.lookup(name_token)
      value = expr.is_a?(Expression::CompoundAssignment) ? @interpreter.evaluate(expr.value) : 1
      if var.is_a?(Float)
        return @interpreter.scope.assign(name_token, var - value) if value.is_a?(Float)
        return @interpreter.scope.assign(name_token, var - value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(name_token, var - value) if value.is_a?(Int)
        return @interpreter.scope.assign(name_token, var.to_f - value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class MulAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value)
      op = "*="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var * value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var * value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var * value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f * value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class DivAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value)
      op = "/="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var / value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var / value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var / value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f / value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class PowAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value)
      op = "^="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var ** value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var ** value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var ** value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f ** value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class ModAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value)
      op = "%="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var % value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var % value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var % value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f % value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end
end
