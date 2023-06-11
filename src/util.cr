require "yaml"

module Cosmo::Util
  extend self

  # This module encodes text with a color code
  module Color
    extend self

    private def encode(text : String, code : Int, reset_code = 0) : String
      "\e[#{code}m#{text}\e[#{reset_code}m"
    end

    def bold(text : String)
      encode(text, 1, 22)
    end

    def faint(text : String)
      encode(text, 2, 22)
    end

    def red(text : String)
      encode(text, 31)
    end

    def light_purple(text : String)
      encode(text, 95)
    end

    def light_yellow(text : String)
      encode(text, 93)
    end

    def light_green(text : String)
      encode(text, 92)
    end

    def light_cyan(text : String)
      encode(text, 96)
    end
  end

  # This module is responsible for pretty-printing Cosmo values
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

    def any_value(value : T) : String forall T
      if value.is_a?(Hash)
        hashmap(value, @@indent)
      elsif value.is_a?(Array(ValueType) | Spread)
        s = String::Builder.new
        s.write("*".to_slice) if value.is_a?(Spread)
        s.write("[".to_slice)

        enumerable = value.is_a?(Spread) ? value.array : value
        multiline = enumerable.size >= 10
        push_indent(s) if multiline

        enumerable.each_with_index do |v, i|
          s.write(('\n' + (TAB * @@indent)).to_slice) if multiline
          s.write(any_value(v).to_slice)
          if i == enumerable.size - 1
            s.write(('\n' + TAB * (@@indent - 1)).to_slice) if multiline
          else
            s.write(", ".to_slice)
          end
        end

        pop_indent if multiline
        s.write("]".to_slice)
        s.to_s
      elsif value.is_a?(ClassInstance)
        Util::Color.light_yellow(value.name)
      elsif value.is_a?(String | Char)
        delim = value.is_a?(String) ? "\"" : "'"
        Util::Color.light_green(delim + value.to_s + delim)
      elsif value.is_a?(Num | Range(Int128 | Int64 | Int32 | Int16 | Int8 | UInt, Int128 | Int64 | Int32 | Int16 | Int8 | UInt))
        Util::Color.light_purple(value.to_s)
      elsif value.nil? || value.is_a?(Bool)
        Util::Color.bold Util::Color.light_cyan(value.to_s)
      else
        value.to_s
      end
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

  # Formats the distance between two time spans into a string
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
end

Cosmo::Version = "v" + Cosmo::Util.get_shard["version"].to_s
