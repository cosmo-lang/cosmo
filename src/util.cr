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
  path = File.expand_path File.join File.dirname(__FILE__), "..", "shard.yml"
  raw_yaml = File.read(path)
  YAML.parse(raw_yaml)
end
Cosmo::Version = "v" + get_shard["version"].to_s

module Stringify
  extend self

  @@indent = 0
  private def push_indent(s : String::Builder) : Nil
    @@indent += 1
    s.write((TAB * @@indent).to_slice)
  end

  private def pop_indent : Nil
    @@indent -= 1
  end

  def hashmap(hash : Hash, base_indent : Int = 0) : String
    @@indent = base_indent
    s = String::Builder.new("{")
    push_indent(s)

    hash.each_with_index do |entry, i|
      s.write(("\n" + (TAB * @@indent)).to_slice) if i == 0
      key, value = entry
      s.write('"'.to_s.to_slice) if key.is_a?(String)
      s.write(key.to_s.to_slice)
      s.write('"'.to_s.to_slice) if key.is_a?(String)
      s.write(" -> ".to_slice)
      if value.is_a?(Hash)
        s.write(Stringify.hashmap(value, @@indent).to_slice)
      else
        s.write('"'.to_s.to_slice) if value.is_a?(String)
        s.write((value.nil? ? "none" : value.to_s).to_slice)
        s.write('"'.to_s.to_slice) if value.is_a?(String)
      end

      s.write(",".to_slice) unless i == hash.size - 1
      s.write("\n".to_slice)
      s.write((TAB * @@indent).to_slice) unless i == hash.size - 1
    end

    pop_indent
    s.write("#{TAB * @@indent}}".to_slice)
    s.to_s
  end
end
