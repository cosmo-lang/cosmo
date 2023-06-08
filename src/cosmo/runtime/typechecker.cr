require "../logger"

private alias CrystalClass = Class
module Cosmo
  class Spread
    getter array : Array(ValueType)

    def initialize(@array)
    end

    def to_s : String
      Stringify.any_value(@array)
    end
  end

  alias UInt = UInt64 | UInt32 | UInt16 | UInt8
  alias RangeType = Range(
    Int128 | Int64 | Int32 | Int16 | Int8 | UInt,
    Int128 | Int64 | Int32 | Int16 | Int8 | UInt
  )

  alias NestableValueType = LiteralType | RangeType | Callable | Class | ClassInstance | Type | Spread
  alias ValueType = NestableValueType | Array(ValueType) | Hash(ValueType, ValueType)
end

module Cosmo::TypeChecker
  extend self

  TYPE_MAP = {
    Int128 => "bigint",
    Int64 => "int",
    Int32 => "int",
    Int16 => "int",
    Int8 => "int",
    UInt64 => "uint",
    UInt32 => "uint",
    UInt32 => "uint",
    UInt16 => "uint",
    UInt8 => "uint",
    Float64 => "float",
    Float32 => "float",
    String => "string",
    Char => "char",
    Bool => "bool",
    Nil => "none",
    ClassInstance => "classinstance",
    Class => "class",
    Type => "type",
    Function => "Function",
    Array(Int64) => "int[]",
    Array(Int32) => "int[]",
    Array(Int16) => "int[]",
    Array(Int8) => "int[]",
    Array(UInt64) => "uint[]",
    Array(UInt32) => "uint[]",
    Array(UInt16) => "uint[]",
    Array(UInt8) => "uint[]",
    Array(Float64) => "float[]",
    Array(Float32) => "float[]",
    Array(String) => "string[]",
    Array(Char) => "char[]",
    Array(Bool) => "bool[]",
    Array(Function) => "fn[]",
    Array(ValueType) => "any[]",
    Array => "any[]",
    Hash(ValueType, ValueType) => "Table",
    RangeType => "Range",
    Spread => "Spread"
  }

  REGISTERED = [] of Type
  ALIASES = {} of String => String

  private def report_mismatch(typedef : String, value : ValueType, token : Token)
    got_type = value.is_a?(ClassInstance) ? value.name : get_mapped(value.class)
    if value.is_a?(Int) && value >= 0
      got_type = "uint"
    end

    Logger.report_error("Type mismatch", "Expected '#{typedef}', got '#{got_type}'", token)
  end

  def get_mapped(t : CrystalClass) : String
    return t.to_s if t < Intrinsic::IFunction
    unless TYPE_MAP.has_key?(t)
      raise "Unhandled type to map: #{t}"
    end
    TYPE_MAP[t]
  end

  def register_intrinsics
    register_type("Range")
    register_type("type")
    register_type("class")
    register_type("Function")
    register_type("bigint")
    register_type("uint")
    register_type("int")
    register_type("float")
    register_type("bool")
    register_type("string")
    register_type("char")
    register_type("void")
  end

  def array_as_value_type(arr : Array(T)) : Array(ValueType) forall T
    arr.map { |e| as_value_type(e) }.as Array(ValueType)
  end

  def hash_as_value_type(hash : Hash(K, V)) : Hash(ValueType, ValueType) forall K, V
    res = {} of ValueType => ValueType
    hash.each { |k, v| res[as_value_type(k)] = as_value_type(v) }
    res
  end

  def as_value_type(value : T) : ValueType forall T
    value.is_a?(Array) ? array_as_value_type(value)
      : value.is_a?(Hash) ? hash_as_value_type(value)
        : value.is_a?(Spread) ? as_value_type(value.array)
          : value.is_a?(Int128) && value <= Int64::MAX ? value.to_i64
            : value.is_a?(JSON::Any) ? as_value_type(value.raw) : value.as ValueType
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
    if typedef.includes?("|")
      types = typedef.split("|")
      resolved = true
      types.each do |t|
        if get_registered_type?(t, token).nil?
          resolved = false
          break
        end
      end
      Type.new(typedef) if resolved
    elsif typedef.ends_with?("[]")
      value_type = typedef.rchop("[]")
      Type.new(typedef) unless get_registered_type?(value_type, token).nil?
    elsif typedef.includes?("->") && typedef.split("->", 2).size == 2
      types = typedef.split("->", 2)
      key_type = types.first
      value_type = types.last
      Type.new(typedef) unless get_registered_type?(key_type, token).nil? && get_registered_type?(value_type, token).nil?
    else
      REGISTERED.find { |t| t.name == typedef }
    end
  end

  def get_registered_type(name : String, token : Token) : Type?
    type = get_registered_type?(name, token)
    Logger.report_error("Could not resolve type", "'#{name}'", token) if type.nil?
    type
  end

  def cast?(value : T, type : Token) : ValueType forall T
    if is?(type.lexeme, "", type) # if the type is a string
      if value.is_a?(ClassInstance)
        to_string = value.get_method("to_string", include_private: false, required: false)
        to_string.nil? ?
          value.name
          : to_string.call([] of ValueType)
      else
        value.to_s
      end
    elsif type.lexeme.includes?("char") && value.to_s.size == 1  # if the type is a char
      value.to_s.chars.first
    elsif is?(type.lexeme, 1, type) && (value.is_a?(String) || value.is_a?(Float) || value.is_a?(Int) || value.is_a?(Bool)) # if the type is an integer
      if value.is_a?(Bool)
        value ? 1 : 0
      else
        value.to_i
      end
    elsif is?(type.lexeme, 1.0, type) && (value.is_a?(String) || value.is_a?(Float) || value.is_a?(Int) || value.is_a?(Bool)) # if the type is a float
      if value.is_a?(Bool)
        value ? 1.0 : 0.0
      else
        value.to_f
      end
    elsif is?(type.lexeme, true, type) && (value.is_a?(Float) || value.is_a?(Int)) # if the type is a boolean
      if value.to_i == 1 || value.to_i == 0
        value.to_i == 1
      end
    end
  end

  def cast(value : ValueType, type : Token) : ValueType
    begin
      casted = cast?(value, type)
      if casted.nil?
        got_type = value.is_a?(ClassInstance) ? value.name : get_mapped(value.class)
        Logger.report_error("Failed to cast", "'#{got_type}' to '#{type.lexeme}'", type)
      end
      casted
    rescue ex : Exception
      got_type = value.is_a?(ClassInstance) ? value.name : get_mapped(value.class)
      Logger.report_error("Failed to cast", "'#{got_type}' to '#{type.lexeme}'", type)
    end
  end

  def is?(typedef : String, value : ValueType, token : Token, except = false) : Bool
    typedef = typedef.gsub(/\s+/, "")

    case typedef
    when "Range"
      value.is_a?(Range)
    when "class"
      value.is_a?(Class)
    when "type"
      value.is_a?(Type)
    when "Function"
      value.is_a?(Callable)
    when "bigint"
      value.is_a?(Int)
    when "uint"
      value.is_a?(Int) && value >= 0
    when "int"
      value.is_a?(Int64 | Int32 | Int16 | Int8)
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
          matches ||= is?(type.strip, value, token, except: true)
        end
      elsif typedef.starts_with?("(")
        next_paren_idx = typedef.index(")") || typedef.size
        ungrouped_chars = typedef.lchop.chars
        ungrouped_chars.delete_at(next_paren_idx - 1, 1)
        ungrouped_type = ungrouped_chars.join
        matches = is?(ungrouped_type, value, token)
      elsif typedef.includes?("->") && typedef.split("->", 2).size == 2
        types = typedef.split("->", 2)
        key_type = types.first.strip
        value_type = types.last.strip

        matches = value.is_a?(Hash)
        if value.is_a?(Hash)
          value.as(Hash).each do |k, v|
            matches &&= is?(key_type, k, token)
            matches &&= is?(value_type, v, token)
          end
        end
      elsif typedef.ends_with?("[]")
        value_type = typedef.rchop("[]")
        matches = value.is_a?(Array)
        if value.is_a?(Array)
          value.as(Array).each { |v| matches &&= is?(value_type, v, token) }
        end
      elsif typedef.ends_with?("?")
        non_nullable_type = typedef.rchop
        matches = is?(non_nullable_type + "|void", value, token)
      else # TODO: support interface typedefs
        unless matches
          registered = get_registered_type?(typedef, token)

          unless registered.nil?
            if ALIASES.has_key?(registered.name)
              unaliased = ALIASES[registered.name]
              matches = is?(unaliased, value, token)
            elsif value.is_a?(ClassInstance)
              matches = value.name == registered.name
            else
              unless except
                Logger.report_error("Expected type #{registered.name}, got", get_mapped(value.class), token)
              end
            end
          end
        end
      end

      matches
    end
  end

  def assert(typedef : String, value : ValueType, token : Token) : Nil
    typedef = typedef.gsub(/\s+/, "")
    matches = is?(typedef, value, token)

    # assert key & value types
    if typedef.includes?("|")
      types = typedef.split("|")
      types.each do |type|
        matches ||= is?(type.strip, value, token, except: true)
      end
    elsif typedef.ends_with?("[]")
      value_type = typedef.rchop("[]")
      report_mismatch(typedef, value, token) unless value.is_a?(Array)
      value.as(Array).each { |v| assert(value_type, v, token) }
    elsif typedef.starts_with?("(")
      next_paren_idx = typedef.index(")") || typedef.size
      ungrouped_chars = typedef.lchop.chars
      ungrouped_chars.delete_at(next_paren_idx - 1, 1)
      ungrouped_type = ungrouped_chars.join
      assert(ungrouped_type, value, token)
    elsif typedef.includes?("->") && typedef.split("->", 2).size == 2
      types = typedef.split("->", 2)
      key_type = types.first.strip
      value_type = types.last.strip

      report_mismatch(typedef, value, token) unless value.is_a?(Hash)

      internal = hash_as_value_type(value)
      internal.each do |k, v|
        assert(key_type, k, token)
        assert(value_type, v, token)
      end
    else
      report_mismatch(typedef, value, token) unless matches
    end
  end
end
