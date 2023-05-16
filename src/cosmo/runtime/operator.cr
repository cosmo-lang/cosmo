module Cosmo::Operator
  private alias ExprType = Expression::BinaryOp | Expression::CompoundAssignment

  private abstract class Base
    def initialize(@interpreter : Interpreter)
    end
    abstract def apply(expr : E) : ValueType forall E
  end

  class Plus < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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
      left = @interpreter.evaluate(expr.left.as Expression::Base)
      right = @interpreter.evaluate(expr.right.as Expression::Base)
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

  class PlusAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value.as Expression::Base)
      op = "+="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var + value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var + value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var + value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f + value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(String)
        return @interpreter.scope.assign(expr.name, var + value) if value.is_a?(String)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class MinusAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value.as Expression::Base)
      op = "-="
      if var.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var - value) if value.is_a?(Float)
        return @interpreter.scope.assign(expr.name, var - value.to_f) if value.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      elsif var.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var - value) if value.is_a?(Int)
        return @interpreter.scope.assign(expr.name, var.to_f - value) if value.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", value.class.to_s, expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", var.class.to_s, expr.operator)
    end
  end

  class MulAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      var = @interpreter.scope.lookup(expr.name)
      value = @interpreter.evaluate(expr.value.as Expression::Base)
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
      value = @interpreter.evaluate(expr.value.as Expression::Base)
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
      value = @interpreter.evaluate(expr.value.as Expression::Base)
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
      value = @interpreter.evaluate(expr.value.as Expression::Base)
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
