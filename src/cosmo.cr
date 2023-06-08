require "./cosmo/logger"
require "./util"
require "./cosmo/runtime/interpreter"
require "option_parser"

module Cosmo
  extend self

  # Parse options
  @@options = {} of Symbol => Bool
  begin
    OptionParser.new do |opts|
      opts.banner = "Thank you for using Cosmo!\nUsage: cosmo [OPTIONS] [FILE]"
      opts.on("-a", "--ast", "Outputs the AST") do
        @@options[:ast] = true
      end
      opts.on("-B", "--benchmark", "Outputs the execution time of the lexer, parser, resolver, and interpreter") do
        @@options[:benchmark] = true
      end
      opts.on("-e", "--error-trace", "Toggles full error message mode (shows Cosmo source code backtraces)") do
        Logger.debug = true
      end
      opts.on("-h", "--help", "Outputs help menu for Cosmo CLI") do
        puts opts
        exit
      end
      opts.on("-v", "--version", "Outputs the current version of Cosmo") do
        puts "Cosmo #{Version}"
        exit
      end
    end.parse(ARGV)
  rescue ex : OptionParser::InvalidOption
    puts ex.message
  end

  @@interpreter = Interpreter.new(
    output_ast: @@options.has_key?(:ast),
    run_benchmarks: @@options.has_key?(:benchmark)
  )

  def read_source(source : String, file_path : String) : ValueType
    begin
      @@interpreter.interpret(source, file_path)
    rescue ex : Exception
      msg = "BUG: #{ex.inspect_with_backtrace}\nYou've found a bug! Please open an issue, including source code so we can reproduce the bug: https://github.com/cosmo-lang/cosmo/issues"
      abort msg, 1
    end
  end

  # Reads a file at `path` and returns it's contents
  def read_file(path : String)
    begin
      contents = File.read(path)
      read_source(contents, file_path: path)
    rescue ex : Exception
      abort "Failed to read file \"#{path}\": \n#{ex.message}\n\t#{ex.backtrace.join("\n\t")}", 1
    end
  end

  private def rainbow(text : String) : String
    colors = [31, 33, 32, 36, 35]  # red, yellow, green, cyan, and purple
    text_chars = text.chars
    color_index = 0
    rainbow_str = ""

    text_chars.each do |char|
      color_code = colors[color_index]
      rainbow_str += "\e[#{color_code}m#{char}\e[0m"  # Apply color and reset back to default
      color_index = (color_index + 1) % colors.size
    end

    rainbow_str
  end

  # Starts the REPL
  def run_repl
    puts "Welcome to the #{rainbow "Cosmo"} REPL!"
    loop do
      STDOUT.write(Util::Color.light_green("» ").to_slice)
      line = STDIN.gets
      break if line.nil? || line.chomp.empty?

      result = read_source(line, file_path: "repl")
      puts Util::Stringify.any_value(result)
    end
  end

  def options
    @@options
  end
end

if ARGV.empty?
  Cosmo.run_repl
else
  Cosmo.read_file(ARGV.first)
end
