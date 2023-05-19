require "../logger"
require "./global_intrinsics"
require "./type"

module Cosmo
  private alias NonNestableValueType = LiteralType | Range(Int64 | Int32 | Int16 | Int8, Int64 | Int32 | Int16 | Int8) | Callable | Type
  alias ValueType = NonNestableValueType | Array(ValueType) | Hash(ValueType, ValueType)
end

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
    Array(ValueType) => "any[]",
    Array => "any[]",
    Hash => "Table",
    Range(Int16 | Int32 | Int64 | Int8, Int16 | Int32 | Int64 | Int8) => "Range"
  }

  REGISTERED = [] of Type
  ALIASES = {} of String => String

  private def report_mismatch(typedef : String, value : ValueType, token : Token)
    got_type = get_mapped(value.class)
    Logger.report_error("Type mismatch", "Expected '#{typedef}', got '#{got_type}'", token)
  end

  def get_mapped(t : Class) : String
    unless TYPE_MAP.has_key?(t)
      raise "Unhandled type to map: #{t}"
    end
    TYPE_MAP[t]
  end

  def register_intrinsics
    register_type("Range")
    register_type("type")
    register_type("func")
    register_type("int")
    register_type("float")
    register_type("bool")
    register_type("string")
    register_type("char")
    register_type("void")
  end

  def cast_array(arr : Array(T)) : Array(ValueType) forall T
    arr.map { |e| cast(e) }
  end

  def cast_hash(hash : Hash(K, V)) : Hash(ValueType, ValueType) forall K, V
    res = {} of ValueType => ValueType
    hash.each { |k, v| res[cast(k)] = cast(v) }
    res
  end

  def cast(value : T) : ValueType forall T
    value.is_a?(Array) ? cast_array(value)
      : value.is_a?(Hash) ? cast_hash(value) : value.as ValueType
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

  def get_registered_type?(typedef : String, token : Token) : Type?
    if typedef.ends_with?("[]")
      value_type = typedef[0..-3]
      Type.new(typedef) unless get_registered_type?(value_type, token).nil?
    elsif typedef.includes?("->") && typedef.split("->", 2).size == 2
      types = typedef.split("->", 2)
      key_type = types.first
      value_type = types.last
      Type.new(typedef) unless get_registered_type?(key_type, token).nil? && get_registered_type?(value_type, token).nil?
    elsif typedef.includes?("|")
      types = typedef.split("|")
      resolved = true
      types.each do |t|
        if get_registered_type?(t, token).nil?
          resolved = false
          break
        end
      end
      Type.new(typedef) if resolved
    else
      REGISTERED.find { |t| t.name == typedef }
    end
  end

  def get_registered_type(name : String, token : Token) : Type?
    type = get_registered_type?(name, token)
    Logger.report_error("Could not resolve type", "'#{name}'", token) if type.nil?
    type
  end

  def is?(typedef : String, value, token : Token) : Bool
    case typedef
    when "Range"
      value.is_a?(Range)
    when "type"
      value.is_a?(Type)
    when "func"
      value.is_a?(Function) || value.is_a?(IntrinsicFunction)
    when "int"
      value.is_a?(Int)
    when "float"
      value.is_a?(Float)
    when "bool"
      value.is_a?(Bool)
    when "string"
      value.is_a?(String)
    when "char"
      value.is_a?(Char)
    when "none", "void"
      value == nil
    when "any"
      true
    else
      matches = false

      if typedef.includes?("|")
        types = typedef.split("|")
        types.each do |type|
          matches = true if is?(type.strip, value, token)
        end
      elsif typedef.ends_with?("?")
        non_nullable_type = typedef[0..-2]
        matches = is?(non_nullable_type + "|void", value, token)
      end

      matches
    end
  end

  def assert(typedef : String, value : ValueType, token : Token) : Nil
    matches = is?(typedef, value, token)
    unless matches
      if typedef.starts_with?("(")
        ungrouped_type = typedef[1..-2]
        assert(ungrouped_type, value, token)
      elsif typedef.ends_with?("[]")
        value_type = typedef[0..-3]
        report_mismatch(typedef, value, token) unless value.is_a?(Array)
        value.as(Array).each { |v| assert(value_type, v, token) }
      elsif typedef.includes?("->") && typedef.split("->", 2).size == 2
        types = typedef.split("->", 2)
        key_type = types.first.strip
        value_type = types.last.strip

        report_mismatch(typedef, value, token) unless value.is_a?(Hash)

        internal = cast_hash(value)
        internal.each do |k, v|
          assert(key_type, k, token)
          assert(value_type, v, token)
        end
      else
        registered = get_registered_type?(typedef, token)
        unless registered.nil?
          if ALIASES.has_key?(registered.name)
            unaliased = ALIASES[registered.name]
            assert(unaliased, value, token) unless typedef == unaliased
          else
            report_mismatch(typedef, value, token)
          end
        else
          raise "Type '#{typedef}' is unregistered and is unhandled in TypeChecker."
        end
      end
    end
  end
end
