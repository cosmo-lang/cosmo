require "../logger"
require "./intrinsics"
require "./type"

private alias NonNestableValueType = LiteralType | Cosmo::Callable | Cosmo::Type
alias ValueType = NonNestableValueType | Array(ValueType) | Hash(ValueType, ValueType)

module Cosmo::TypeChecker
  extend self

  TYPE_MAP = {
    Int64 => "int",
    Int32 => "int",
    Int16 => "int",
    Int8 => "int",
    Float64 => "float",
    Float32 => "float",
    String => "string",
    Char => "char",
    Bool => "bool",
    Nil => "none",
    Function => "fn",
    PutsIntrinsic => "fn",
    Array(Int64) => "int[]",
    Array(Int32) => "int[]",
    Array(Int16) => "int[]",
    Array(Int8) => "int[]",
    Array(Float64) => "float[]",
    Array(Float32) => "float[]",
    Array(String) => "string[]",
    Array(Char) => "char[]",
    Array(Bool) => "bool[]",
    Array(Function) => "fn[]",
    Array => "any[]"
  }

  REGISTERED = [] of Type
  ALIASES = {} of String => String

  private def report_mismatch(typedef : String, value : ValueType, token : Token)
    got_type = TYPE_MAP[value.class]
    Logger.report_error("Type mismatch", "Expected '#{typedef}', got '#{got_type}'", token)
  end

  def get_mapped(t : Class) : String
    TYPE_MAP[t]
  end

  def register_intrinsics
    register_type("int")
    register_type("float")
    register_type("bool")
    register_type("string")
    register_type("char")
    register_type("void")
  end

  def reset
    ALIASES.clear
    REGISTERED.clear
    register_intrinsics
  end

  def register_type(name : String) : Type
    type = Type.new(name)
    REGISTERED << type
    type
  end

  def alias_type(alias_name : String, original : String) : Type
    ALIASES[alias_name] = original
    register_type(alias_name)
  end

  def get_registered_type?(name : String, token : Token) : Type?
    REGISTERED.find { |t| t.name == name }
  end

  def get_registered_type(name : String, token : Token) : Type?
    type = get_registered_type?(name, token)
    Logger.report_error("Could not resolve type", "'#{name}'", token) if type.nil?
    type
  end

  def assert(typedef : String, value : ValueType, token : Token) : Nil
    case typedef
    when "type"
      report_mismatch(typedef, value, token) unless value.is_a?(Type)
    when "fn"
      report_mismatch(typedef, value, token) unless value.is_a?(Function) || value.is_a?(IntrinsicFunction)
    when "int"
      report_mismatch(typedef, value, token) unless value.is_a?(Int)
    when "float"
      report_mismatch(typedef, value, token) unless value.is_a?(Float)
    when "bool"
      report_mismatch(typedef, value, token) unless value.is_a?(Bool)
    when "string"
      report_mismatch(typedef, value, token) unless value.is_a?(String)
    when "char"
      report_mismatch(typedef, value, token) unless value.is_a?(Char)
    when "none", "void"
      report_mismatch(typedef, value, token) unless value == nil
    when "any"
    else
      if typedef.ends_with?("[]")
        value_type = typedef[0..-3]
        report_mismatch(typedef, value, token) unless value.is_a?(Array)
        value.as(Array).each { |v| assert(value_type, v, token) }
        return
      else
        registered = get_registered_type?(typedef, token)
        unless registered.nil?
          if ALIASES.has_key?(registered.name)
            unaliased = ALIASES[registered.name]
            return assert(unaliased, value, token) unless typedef == unaliased
          else
            raise "Type is registered, but has no alias and is unhandled in TypeChecker."
          end
        end
      end
      raise "Unhandled type '#{typedef}' in TypeChecker"
    end
  end
end
