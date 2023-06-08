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

# TODO: stringify hashes nested in arrays
# This class is responsible for pretty-printing Cosmo values
module Cosmo::Stringify
  extend self

  @@indent = 0
  private def push_indent(s : String::Builder) : Nil
    @@indent += 1
    s.write((TAB * @@indent).to_slice)
  end

  private def pop_indent : Nil
    @@indent -= 1
  end

  def any_value(value : T) : String forall T
    s = String::Builder.new

    if value.is_a?(Hash)
      s.write(hashmap(value, @@indent).to_slice)
    elsif value.is_a?(Array) || value.is_a?(Spread)
      s.write("*".to_slice) if value.is_a?(Spread)
      s.write("[".to_slice)

      multiline = value.size >= 10
      push_indent(s) if multiline

      enumerable = value.is_a?(Spread) ? value.array : value
      value.each_with_index do |v, i|
        s.write(('\n' + (TAB * @@indent)).to_slice) if multiline
        s.write(any_value(v).to_slice)
        if i == value.size - 1
          s.write(('\n' + TAB * (@@indent - 1)).to_slice) if multiline
        else
          s.write(", ".to_slice)
        end
      end

      pop_indent if multiline
      s.write("]".to_slice)
    elsif value.is_a?(ClassInstance)
      value.name
    else
      s.write('"'.to_s.to_slice) if value.is_a?(String)
      s.write((value.nil? ? "none" : value.to_s).to_slice)
      s.write('"'.to_s.to_slice) if value.is_a?(String)
    end

    s.to_s
  end

  private def stringify_hash_entry(h : Hash, entry : Tuple(ValueType, ValueType), i : Int) : String
    s = String::Builder.new

    s.write(('\n' + (TAB * @@indent)).to_slice) if i == 0
    key, value = entry

    s.write(any_value(key).to_slice)
    s.write(" -> ".to_slice)
    s.write(any_value(value).to_slice)

    s.write(",".to_slice) unless i == h.size - 1
    s.write("\n".to_slice)
    s.write((TAB * @@indent).to_slice) unless i == h.size - 1
    s.to_s
  end

  def hashmap(h : Hash, base_indent : Int = 0) : String
    @@indent = base_indent
    s = String::Builder.new("{{")
    push_indent(s)

    h.each_with_index do |entry, i|
      s.write(stringify_hash_entry(h, entry, i).to_slice)
    end

    pop_indent
    s.write("#{TAB * @@indent}}}".to_slice)
    s.to_s
  end
end
