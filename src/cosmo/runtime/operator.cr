module Cosmo::Operator
  private abstract class Base
    def initialize(@interpreter : Interpreter)
    end
    abstract def apply(expr : E) : ValueType forall E
  end

  class Plus < Base
    def apply(expr : Expression::BinaryOp, op : String = "+") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "add$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "add$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left + right if right.is_a?(Float)
        return left + right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left + right if right.is_a?(Int)
        return left.to_f + right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(String) || left.is_a?(Char)
        return left.to_s + right.to_s if right.is_a?(String) || right.is_a?(Char)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Minus < Base
    def apply(expr : Expression::BinaryOp, op : String = "-") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "sub$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "sub$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left - right if right.is_a?(Float)
        return left - right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left - right if right.is_a?(Int)
        return left.to_f - right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Mul < Base
    def apply(expr : Expression::BinaryOp, op : String = "*") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "mul$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "mul$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left * right if right.is_a?(Float)
        return left * right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left * right if right.is_a?(Int)
        return left.to_f * right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(String) || left.is_a?(Char)
        if right.is_a?(Int)
          if right < 0
            Logger.report_error("Invalid '#{op}' operand type", "'int', expected 'uint'", expr.operator)
          end
          return left.to_s * right
        end
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Div < Base
    def apply(expr : Expression::BinaryOp, op : String = "/") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "div$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "div$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left / right if right.is_a?(Float)
        return left / right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left / right if right.is_a?(Int)
        return left.to_f / right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(String)
        if right.is_a?(String) || right.is_a?(Char)
          return TypeChecker.array_as_value_type(left.split(right.to_s))
        end
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class IntDiv < Base
    def apply(expr : Expression::BinaryOp, op : String = "//") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "idiv$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "idiv$", op, expr.operator)
      end

      if left.is_a?(Float)
        return (left // right).to_i if right.is_a?(Float)
        return (left // right.to_f).to_i if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return (left // right).to_i if right.is_a?(Int)
        return (left.to_f // right).to_i if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Pow < Base
    def apply(expr : Expression::BinaryOp, op : String = "^") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "pow$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "pow$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left ** right if right.is_a?(Float)
        return left ** right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left ** right if right.is_a?(Int)
        return left.to_f ** right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Mod < Base
    def apply(expr : Expression::BinaryOp, op : String = "%") : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "mod$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "mod$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left % right if right.is_a?(Float)
        return left % right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left % right if right.is_a?(Int)
        return left.to_f % right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class LT < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '<'

      # if left.is_a?(ClassInstance)
      #   return @interpreter.call_meta_method(left, right, "lt$", op, expr.operator)
      # elsif right.is_a?(ClassInstance)
      #   return @interpreter.call_meta_method(right, left, "lt$", op, expr.operator)
      # end

      if left.is_a?(Float)
        return left < right if right.is_a?(Float)
        return left < right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left < right if right.is_a?(Int)
        return left.to_f < right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class LTE < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "<="

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "lte$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "lte$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left <= right if right.is_a?(Float)
        return left <= right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left <= right if right.is_a?(Int)
        return left.to_f <= right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class GT < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = '>'

      # if left.is_a?(ClassInstance)
      #   return @interpreter.call_meta_method(left, right, "gt$", op, expr.operator)
      # elsif right.is_a?(ClassInstance)
      #   return @interpreter.call_meta_method(right, left, "gt$", op, expr.operator)
      # end

      if left.is_a?(Float)
        return left > right if right.is_a?(Float)
        return left > right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left > right if right.is_a?(Int)
        return left.to_f > right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class GTE < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = ">="

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "gte$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "gte$", op, expr.operator)
      end

      if left.is_a?(Float)
        return left >= right if right.is_a?(Float)
        return left >= right.to_f if right.is_a?(Int)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      elsif left.is_a?(Int)
        return left >= right if right.is_a?(Int)
        return left.to_f >= right if right.is_a?(Float)
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
    end
  end

  class Bnot < Base
    def apply(expr : Expression::UnaryOp) : ValueType
      operand = @interpreter.evaluate(expr.operand)
      op = "~"

      if operand.is_a?(ClassInstance)
        return @interpreter.call_meta_method(operand, nil, "bnot$", op, expr.operator)
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
        return @interpreter.call_meta_method(left, right, "bxor$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "bxor$", op, expr.operator)
      end

      if left.is_a?(Int)
        return left ^ right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
    end
  end

  class Bor < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "|"

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "bor$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "bor$", op, expr.operator)
      end


      if left.is_a?(Int)
        return left | right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
    end
  end

  class Band < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "&"

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "band$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "band$", op, expr.operator)
      end

      if left.is_a?(Int)
        return left & right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
    end
  end

  class Bshr < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = ">>"

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "bshr$", op, expr.operator)
      elsif right.is_a?(ClassInstance)
        return @interpreter.call_meta_method(right, left, "bshr$", op, expr.operator)
      end

      if left.is_a?(Int)
        return left >> right if right.is_a?(Int)
      else
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
    end
  end

  class Bshl < Base
    def apply(expr : Expression::BinaryOp) : ValueType
      left = @interpreter.evaluate(expr.left)
      right = @interpreter.evaluate(expr.right)
      op = "<<"

      if left.is_a?(ClassInstance)
        return @interpreter.call_meta_method(left, right, "bshl$", op, expr.operator)
      elsif right.is_a?(ClassInstance) && !left.is_a?(Array)
        return @interpreter.call_meta_method(right, left, "bshl$", op, expr.operator)
      end

      if left.is_a?(Int)
        return left << right if right.is_a?(Int)
      elsif left.is_a?(Array) # TODO: use VectorIntrinsics::Push instead
        if expr.left.is_a?(Expression::Access) || expr.left.is_a?(Expression::Index)
          prop_assignment = Expression::PropertyAssignment.new(expr.left, left << right)
          return @interpreter.evaluate(prop_assignment)
        else
          access = @interpreter.add_object_value(expr.operator, left, left.size, right)
          return @interpreter.scope.assign(expr.token, access)
        end
      else
        Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(left.class), expr.operator)
      end
      Logger.report_error("Invalid '#{op}' operand type", TypeChecker.get_mapped(right.class), expr.operator)
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

  ## this is fucked up
  class AndAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::And
      fixed_token.lexeme = "and"
      expr.token

      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment)
      value = @interpreter.evaluate(expr.value)
      if expr.name.is_a?(Expression::Var)
        @interpreter.scope.assign(expr.name.token, var_value && value)
      else
        @interpreter.evaluate(prop_assignment)
      end
    end
  end

  class OrAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Or
      fixed_token.lexeme = "or"

      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment.object)
      value = @interpreter.evaluate(expr.value)
      if expr.name.is_a?(Expression::Var)
        @interpreter.scope.assign(expr.name.token, var_value || value)
      else
        @interpreter.evaluate(prop_assignment)
      end
    end
  end

  class CoalesceAssign < Base
    def apply(expr : Expression::CompoundAssignment) : ValueType
      fixed_token = expr.token
      fixed_token.type = Syntax::Or
      fixed_token.lexeme = "?:"

      binary = Expression::BinaryOp.new(expr.name, fixed_token, expr.value)
      prop_assignment = Expression::PropertyAssignment.new(expr.name, binary)
      var_value = @interpreter.evaluate(expr.name.is_a?(Expression::Var) ? expr.name : prop_assignment.object)
      value = @interpreter.evaluate(expr.value)
      if expr.name.is_a?(Expression::Var)
        @interpreter.scope.assign(expr.name.token, var_value.nil? ? value : var_value)
      else
        @interpreter.evaluate(prop_assignment)
      end
    end
  end
end
