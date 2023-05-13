require "./cosmo/logger"
require "./cosmo/runtime/interpreter"
require "option_parser"
require "readline"

module Cosmo
  # Parse options
  @@options = {} of Symbol => Bool
  OptionParser.new do |opts|
    opts.banner = "Usage: cosmo [OPTIONS] [FILE]"
    opts.on("-h", "--help", "Outputs help menu for Cosmo CLI") do
      puts opts
      exit
    end
    opts.on("-a", "--ast", "Output the AST") do
      @@options[:ast] = true
    end
  end.parse(ARGV)



  @@interpreter = Interpreter.new(output_ast: @@options.has_key?(:ast))

  def self.read_source(source : String, file_path : String) : ValueType
    @@interpreter.interpret(source, file_path)
  end

  # Reads a file at `path` and returns it's contents
  def self.read_file(path : String)
    begin
      contents = File.read(path)
      read_source(contents, file_path: path)
    rescue e : Exception
      raise "Failed to read file \"#{path}\": #{e}"
      exit 1
    end
  end

  def self.read_line : String?
    Readline.readline "➤ ", add_history: true
  end

  # Starts the REPL
  def self.run_repl
    puts "Welcome to the Cosmo REPL"
    loop do
      line = read_line
      break if line.nil?
      puts read_source(line, file_path: "repl")
    end
  end
end

if ARGV.empty?
  Cosmo.run_repl
else
  Cosmo.read_file(ARGV.first)
end
