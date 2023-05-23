module Cosmo::Operator
  private abstract class Base
    def initialize(@interpreter : Interpreter)
    end
    abstract def apply(expr : E) : ValueType forall E
  end

  def self.call_meta_method(
    instance : ClassInstance,
    operand : ValueType,
    name : String,
    op_lexeme : String,
    op_token : Token
  ) : ValueType

    meta_method = instance.get_method(name, include_private: false)
    unless meta_method.nil?
      return meta_method.call([ operand ])
    else
      Logger.report_error("Invalid '#{op_lexeme}' operand type", instance.class.to_s, op_token)
    end
  end

  class Plus < Base
    def apply(expr : Expression::BinaryOp, op : String = "+") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "add$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "add$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "sub$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "sub$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "mul$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "mul$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "div$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "div$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "pow$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "pow$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "mod$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "mod$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "lt$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "lt$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "lte$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "lte$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "gt$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "gt$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "gte$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "gte$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "bnot$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "bnot$", op, expr.operator)
      end

      return ~operand if operand.is_a?(Int)
      Logger.report_error("Invalid '#{op}' operand type", operand.class.to_s, expr.operator)
    end
  end

  class Bxor < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "~"

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "bxor$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "bxor$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "bor$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "bor$", op, expr.operator)
      end


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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "band$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "band$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "bshr$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "bshr$", op, expr.operator)
      end

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

      if left.is_a?(ClassInstance)
        return Operator.call_meta_method(left, right, "bshl$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return Operator.call_meta_method(right, left, "bshl$", op, expr.operator)
      end

      if left.is_a?(Int)
        return left << right if right.is_a?(Int)
      elsif left.is_a?(Array)
        if expr.left.is_a?(Expression::Access) || expr.left.is_a?(Expression::Index)
          prop_assignment = Expression::PropertyAssignment.new(expr.left, left << right)
          return @interpreter.evaluate(prop_assignment)
        else
          access = @interpreter.add_object_value(expr.operator, left, left.size, right)
          return @interpreter.scope.assign(expr.token, access)
        end
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

      fixed_token = expr.token
      fixed_token.type = Syntax::Plus
      fixed_token.lexeme = "+"
      binary = Expression::BinaryOp.new(left, fixed_token, expr.is_a?(Expression::UnaryOp) ? literal : expr.value)

      if left.is_a?(Expression::Var)
        op = Plus.new(@interpreter)
        result = op.apply(binary, op_lexeme)
        @interpreter.scope.assign(left.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(left, binary))
      end
    end
  end

  class MinusAssign < Base
    def apply(expr : Expression::CompoundAssignment | Expression::UnaryOp, op_lexeme : String = "-=") : ValueType
      left = expr.is_a?(Expression::UnaryOp) ? expr.operand : expr.name
      literal = Expression::IntLiteral.new(1, expr.token)

      fixed_token = expr.token
      fixed_token.type = Syntax::Minus
      fixed_token.lexeme = "-"
      binary = Expression::BinaryOp.new(left, fixed_token, expr.is_a?(Expression::UnaryOp) ? literal : expr.value)
      if left.is_a?(Expression::Var)
        op = Minus.new(@interpreter)
        result = op.apply(binary, op_lexeme)
        @interpreter.scope.assign(left.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(left, binary))
      end
    end
  end

  class MulAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Star
      fixed_token.lexeme = "*"
      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      if expr.name.is_a?(Expression::Var)
        op = Mul.new(@interpreter)
        result = op.apply(binary, "*=")
        @interpreter.scope.assign(expr.name.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(expr.name, binary))
      end
    end
  end

  class DivAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Slash
      fixed_token.lexeme = "/"
      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      if expr.name.is_a?(Expression::Var)
        op = Div.new(@interpreter)
        result = op.apply(binary, "/=")
        @interpreter.scope.assign(expr.name.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(expr.name, binary))
      end
    end
  end

  class PowAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Carat
      fixed_token.lexeme = "^"
      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      if expr.name.is_a?(Expression::Var)
        op = Pow.new(@interpreter)
        result = op.apply(binary, "^=")
        @interpreter.scope.assign(expr.name.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(expr.name, binary))
      end
    end
  end

  class ModAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Percent
      fixed_token.lexeme = "%"
      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      if expr.name.is_a?(Expression::Var)
        op = Mod.new(@interpreter)
        result = op.apply(binary, "%=")
        @interpreter.scope.assign(expr.name.token, result)
      else
        @interpreter.evaluate(Expression::PropertyAssignment.new(expr.name, binary))
      end
    end
  end

  ## this is beyond fucked up
  class AndAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::AmpersandColon
      fixed_token.lexeme = "&:"
      expr.token

      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : Expression::PropertyAssignment.new(expr.name, binary))
      value = @interpreter.evaluate(expr.value)
      if expr.name.is_a?(Expression::Var)
        @interpreter.scope.assign(expr.name.token, var_value && value)
      else
        var_value
      end
    end
  end

  class OrAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::PipeColon
      fixed_token.lexeme = "|:"

      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment.object)
      value = @interpreter.evaluate(expr.value)
      if expr.name.is_a?(Expression::Var)
        @interpreter.scope.assign(expr.name.token, var_value || value)
      else
        var_value
      end
    end
  end
end
