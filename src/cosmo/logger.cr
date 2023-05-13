module Cosmo::Logger
  extend self

  def report_error(error_type : String, message : String, token : Token) : Exception
    raise "[#{token.location.line}:#{token.location.position + 1}] #{error_type}: #{message}"
  end

  def report_error(error_type : String, message : String, line : UInt32, pos : UInt32) : Exception
    raise "[#{line}:#{pos + 1}] #{error_type}: #{message}"
  end
end
