# Formats the distance between two time spans into a string
require "yaml"

def get_elapsed(start : Time::Span, finish : Time::Span) : String
  span = finish - start
  ms = span.total_milliseconds.round(5)
  return "#{(ms / 1000).round(2)} seconds"if ms > 1000
  "#{ms}ms"
end

# Returns `shard.yml` as a `YAML::Any`
def get_shard : YAML::Any
  raw_yaml = File.read File.join File.dirname(__FILE__), "..", "shard.yml"
  YAML.parse(raw_yaml)
end
