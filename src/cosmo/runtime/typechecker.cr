require "../logger"

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
    Bool => "bool"
  }

  private def report_mismatch(typedef : String, value : LiteralType, token : Token)
    got_type = TYPE_MAP[value.class]
    Logger.report_error("Type mismatch", "Expected '#{typedef}', got '#{got_type}'", token)
  end

  def assert(typedef : String, value : LiteralType, token : Token)
    case typedef
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
    when "none"
      report_mismatch(typedef, value, token) unless value == nil
    else
      raise "Unhandled type '#{typedef}' in TypeChecker"
    end
  end
end
