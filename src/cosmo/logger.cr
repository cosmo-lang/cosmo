

module Cosmo::Logger
  extend self

  @@debug = false

  def debug=(on : Bool) : Nil
    @@debug = on
  end

  def report_exception(ex : E) forall E
    raise ex
  end

  def report_error(error_type : String, message : String, token : Token) : Exception
    report_error(error_type, message, token.location.line, token.location.position, token.location.file_name)
  end

  def report_error(error_type : String, message : String, line : UInt32, pos : UInt32, file_path : String) : Exception
    full_message = "@#{file_path} [#{line}:#{pos + 1}] #{error_type}: #{message}"
    unless @@debug
      abort full_message, 1
    else
      raise full_message
    end
  end
end
