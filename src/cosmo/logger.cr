module Cosmo::Logger
  extend self

  @@stack_trace = [] of Token
  @@debug = false
  @@trace_level : UInt32 = 0
  @@source : String = ""

  def source : String
    @@source
  end

  def source=(source : String) : Nil
    @@source = source
  end

  def trace_level=(level : UInt32) : Nil
    @@trace_level = level
  end

  def push_file_trace(token : Token) : UInt32
    (@@stack_trace << token)
      .rindex(token)
      .not_nil!
      .to_u
  end

  def push_trace(token : Token) : UInt32
    (@@stack_trace << token)
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

    full_message = ""
    full_message += Util::Color.faint "#{line - 1} |\n"
    full_message += "#{Util::Color.faint "#{line} | "} #{Util::Color.bold(@@source.split('\n')[line - 1]? || "")}\n"

    bottom_line = "#{line + 1} |"
    full_message += Util::Color.faint(bottom_line)
    full_message += "#{(pos == 0 ? "" : " " * (pos - bottom_line.size + 1)) + Util::Color.light_yellow "^"}\n"

    full_message += Util::Color.red "\n#{error_type}: #{message}"
    stack_dump = [] of String

    @@stack_trace.shift(@@trace_level)
    @@stack_trace.each do |tr|
      stack_dump << "\n#{TAB}at #{tr.lexeme} (#{File.basename(tr.location.file_name)}:#{tr.location.line})"
    end
    stack_dump << "\n#{TAB}at #{File.basename(file_path)}:#{line}" if @@trace_level

    full_message += Util::Color.red(stack_dump.join)
    unless @@debug
      abort full_message, 1
    else
      raise full_message
    end
  end
end
