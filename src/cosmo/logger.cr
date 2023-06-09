module Cosmo::Logger
  extend self

  class StackFrame
    getter token : Token
    getter file_source : String

    def initialize(@token, @file_source)
    end

    def to_s : String
      "StackFrame< \n\t#{@token.to_s},\n\tFileSource<\"\n\n#{@file_source}\n\n\"> >"
    end
  end

  @@stack_trace = [] of StackFrame
  @@debug = false
  @@trace_level : UInt32 = 0

  # TODO: expand file paths (so you can have multiple files of the same name)
  @@sources = {} of String => String

  def register_source(file_path : String, source : String) : Nil
    @@sources[file_path] = source
  end

  def trace_level=(level : UInt32) : Nil
    @@trace_level = level
  end

  def push_trace(token : Token) : UInt32
    source = @@sources[token.location.file_name]
    frame = StackFrame.new(token, source)
    (@@stack_trace << frame)
      .rindex(frame)
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

    first_frame = @@stack_trace.first?
    popped_frames = @@stack_trace.pop(@@trace_level)

    last_frame = @@stack_trace.last? || first_frame
    source = last_frame.nil? ? @@sources[file_path] : last_frame.file_source
    unless last_frame.nil?
      file_path = last_frame.token.location.file_name
      line = last_frame.token.location.line
      pos = last_frame.token.location.position
    end

    full_message = Util::Color.faint "#{line - 1} |\n"
    full_message += "#{Util::Color.faint "#{line} | "} #{Util::Color.bold(source.split('\n')[line - 1]? || "")}\n"

    bottom_line = "#{line + 1} |"
    full_message += Util::Color.faint(bottom_line)
    full_message += "#{" " * Math.max(pos.to_i + 1 - bottom_line.size, 0) + Util::Color.light_yellow "^"}\n"

    full_message += Util::Color.red "\n#{error_type}: #{message}"

    stack_dump = [] of String
    first_trace_dump = "\n#{TAB}at #{File.basename(file_path)}:#{line}:#{pos}"
    stack_dump << first_trace_dump if @@stack_trace.empty?

    @@stack_trace.reverse.each do |tr|
      if tr == @@stack_trace.last && tr.token.lexeme != "throw"
        stack_dump << first_trace_dump
      end
      stack_dump << "\n#{TAB}at #{tr.token.lexeme} (#{File.basename(tr.token.location.file_name)}:#{tr.token.location.line}:#{tr.token.location.position})"
    end

    full_message = "" if full_message.nil?
    full_message += Util::Color.red(stack_dump.join)
    unless @@debug
      abort full_message, 1
    else
      raise full_message
    end
  end
end
