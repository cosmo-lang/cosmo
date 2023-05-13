module Cosmo::Logger
  extend self

  def report_error(error_type : String, message : String, token : Token) : Exception
    raise "[#{token.location.line}:#{token.location.position + 1}] #{error_type}: #{message}"
  end

  def report_error(error_type : String, message : String, pos : UInt32, line : UInt32) : Exception
    raise "[#{line}:#{pos + 1}] #{error_type}: #{message}"
  end
end
