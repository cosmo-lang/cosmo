require "./cosmo/runtime/interpreter"
require "optparse"

# Parse options
options = {} of Symbol => Bool
OptionParser.new do |opts|
  opts.banner = "Usage: #{lang_name} [options] [file_path]"
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
  opts.on("-a", "--ast", "Output the AST") do
    options[:ast] = true
  end
end.parse!(into: options)



interpreter = Interpreter.new(output_ast: options[:ast])

def read_source(source : String, repl : Bool = false)
  interpreter.interpret(source, repl)
end

# Reads a file at `path` and returns it's contents
def read_file(path : String) : String
  begin
    File.read(path)
  rescue e : Exception
    raise "Failed to read file \"#{path}\": #{e}"
    exit 1
  end
end

def read_line : String
  print "➤ "
  STDOUT.flush
  gets.chomp
end

# Starts the REPL
def run_repl
  puts "Welcome to the Cosmo REPL"
  loop do
    line = read_line
    break if line.nil?
    read_source(line, repl: true)
  end
end

if ARGV.empty?
  run_repl
else
  file_contents = read_file(ARGV.first)
  read_source(file_contents)
end
