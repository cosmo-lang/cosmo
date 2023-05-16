# Returns the distance between `start` and `finish` as a string
def get_elapsed(start : Time::Span, finish : Time::Span) : String
  dist_span = finish - start
  fmt_time(:benchmark, dist_span)
end

# Formats a time span into a string
private def fmt_time(type : Symbol, span : Time::Span) : String
  case type
  when :benchmark
    ms = span.total_milliseconds.round(5)
    return "#{(ms / 1000).round(2)} seconds"if ms > 1000
    "#{ms}ms"
  else
    raise "Invalid fmt_time type: #{type.to_s}"
  end
end
