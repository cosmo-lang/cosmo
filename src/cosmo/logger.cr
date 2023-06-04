module Cosmo::Logger
  extend self

  @@stack_trace = [] of Token
  @@debug = false

  def push_trace(token : Token) : Nil
    @@stack_trace << token
  end

  def debug=(on : Bool) : Nil
    @@debug = on
  end

  def report_exception(ex : E) forall E
    raise ex
  end

  def report_error(error_type : String, message : String, token : Token) : Exception
    report_error(
      error_type,
      message,
      token.location.line,
      token.location.position,
      token.location.file_name
    )
  end

  def report_error(
    error_type : String,
    message : String,
    line : UInt32,
    pos : UInt32,
    file_path : String
  ) : Exception

    full_message = "#{error_type}: #{message}"
    stack_dump = ["\n#{TAB}at #{file_path}:#{line}"] of String
    @@stack_trace.each do |tr|
      stack_dump << "\n#{TAB}at #{tr.lexeme} (#{tr.location.file_name}:#{tr.location.line})"
    end

    full_message += stack_dump.join
    unless @@debug
      abort full_message, 1
    else
      raise full_message
    end
  end
end
