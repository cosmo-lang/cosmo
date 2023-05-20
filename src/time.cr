# Formats the distance between two time spans into a string
def get_elapsed(start : Time::Span, finish : Time::Span) : String
  span = finish - start
  ms = span.total_milliseconds.round(5)
  return "#{(ms / 1000).round(2)} seconds"if ms > 1000
  "#{ms}ms"
end
