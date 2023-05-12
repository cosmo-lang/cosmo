require "./cosmo/runtime/interpreter"
require "option_parser"
require "readline"

module Cosmo
  # Parse options
  @@options = {} of Symbol => Bool
  OptionParser.new do |opts|
    opts.banner = "Usage: cosmo [options] [file_path]"
    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
    opts.on("-a", "--ast", "Output the AST") do
      @@options[:ast] = true
    end
  end.parse(ARGV)



  @@interpreter = Interpreter.new(output_ast: @@options[:ast])

  def self.read_source(source : String, repl : Bool = false)
    @@interpreter.interpret(source, repl)
  end

  # Reads a file at `path` and returns it's contents
  def self.read_file(path : String) : String
    begin
      File.read(path)
    rescue e : Exception
      raise "Failed to read file \"#{path}\": #{e}"
      exit 1
    end
  end

  def self.read_line : String
    print "➤ "
    STDOUT.flush
    gets.chomp
  end

  # Starts the REPL
  def self.run_repl
    puts "Welcome to the Cosmo REPL"
    loop do
      line = read_line
      break if line.nil?
      read_source(line, repl: true)
    end
  end
end

if ARGV.empty?
  Cosmo.run_repl
else
  file_contents = read_file(ARGV.first)
  Cosmo.read_source(file_contents)
end
