module Cosmo::Logger
  extend self

  @@stack_trace = [] of Token
  @@debug = false
  @@trace_level : UInt32 = 0

  def trace_level=(level : UInt32) : Nil
    @@trace_level = level
  end

  def push_trace(token : Token) : UInt32
    idx = (@@stack_trace << token)
      .rindex(token)
      .not_nil!
      .to_u
  end

  def pop_trace(idx : UInt32) : Nil
    @@stack_trace.delete_at(idx, (idx.to_i - @@stack_trace.size - 1).abs)
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

    @@stack_trace.shift(@@trace_level)

    full_message = "#{error_type}: #{message}"
    stack_dump = [ "\n#{TAB}at #{File.basename(file_path)}:#{line}" ]
    @@stack_trace.reverse.each do |tr|
      stack_dump << "\n#{TAB}at #{tr.lexeme} (#{File.basename(tr.location.file_name)}:#{tr.location.line})"
    end

    full_message += stack_dump.join
    unless @@debug
      abort full_message, 1
    else
      raise full_message
    end
  end
end
