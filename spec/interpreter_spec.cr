require "./spec_helper"

# this still sucks
def shutup(&block : ->)
  out, err, in = Stdio.capture do |io|
    STDOUT.puts ":)"
    STDERR.puts ":("
    io.in.puts ":P"
    block.call
    [io.out.gets, io.err.gets, STDIN.gets]
  end
end

describe Interpreter do
  interpreter = Interpreter.new(output_ast: false, run_benchmarks: false, debug_mode: true)
  it "interprets intrinsics" do
    result = interpreter.interpret("__version", "test")
    result.should eq "Cosmo v#{`shards version`}".strip

    result = interpreter.interpret("puts", "test")
    result.should be_a Callable
    result.should be_a IntrinsicFunction
  end
  it "interprets literals" do
    result = interpreter.interpret("false", "test")
    result.should be_false
    result = interpreter.interpret("true", "test")
    result.should be_true
    result = interpreter.interpret("none", "test")
    result.should be_nil
    result = interpreter.interpret("123", "test")
    result.should eq 123
    result = interpreter.interpret("0b111", "test")
    result.should eq 7
    result = interpreter.interpret("0xabc", "test")
    result.should eq 2748
    result = interpreter.interpret("-0o2004", "test")
    result.should eq -1028
    result = interpreter.interpret("+---10.24335", "test")
    result.should eq 10.24335
    result = interpreter.interpret("\"hello\"", "test")
    result.should eq "hello"
    result = interpreter.interpret("'e'", "test")
    result.should eq 'e'
    result = interpreter.interpret("[1, 2, 3]", "test")
    result.should eq [1, 2, 3]
    result = interpreter.interpret("[[1,2,3], [4,5,6], ['a', 'b', 'c']]", "test")
    result.should eq [[1,2,3], [4,5,6], ['a', 'b', 'c']]
    result = interpreter.interpret("{yes -> true, [123] -> false}", "test")
    result.should eq ({"yes" => true, 123 => false})
    result = interpreter.interpret("any my_range = 5..20", "test")
    result.should eq 5..20
    result = interpreter.interpret("any my_neg_range = -20..-5", "test")
    result.should eq -20..-5
  end
  it "interprets unary operators" do
    result = interpreter.interpret("!false", "test")
    result.should be_true
    result = interpreter.interpret("!true", "test")
    result.should be_false
    result = interpreter.interpret("!!123", "test")
    result.should be_true
    result = interpreter.interpret("0b111", "test")
    result.should eq 7
    result = interpreter.interpret("-0xabc", "test")
    result.should eq -2748
    result = interpreter.interpret("+-10.24335", "test")
    result.should eq 10.24335
  end
  it "interprets binary operators" do
    result = interpreter.interpret("3 * 6 / 2 - 9", "test")
    result.should eq 0
    result = interpreter.interpret("9 ^ 2 / 14 + 6 * 2", "test")
    result.should eq 17.785714285714285
    result = interpreter.interpret("(14 - 3.253 / 14.5) * 27 ^ 4", "test")
    result.should eq 7320947.960482759
    result = interpreter.interpret("true == false", "test")
    result.should eq false
    result = interpreter.interpret("true == false == false != true", "test")
    result.should eq false
  end
  it "interprets variable declarations" do
    result = interpreter.interpret("int x = 0b11 - 0b11011", "test")
    result.should eq -24

    result = interpreter.interpret("char y = 'h'", "test")
    result.should eq 'h'

    result = interpreter.interpret("string z = \"hello world\"", "test")
    result.should eq "hello world"

    result = interpreter.interpret("bool abc = false", "test")
    result.should eq false

    interpreter.interpret("const int foo = 10", "test")
    expect_raises(Exception, "[1:4] Attempt to assign to constant variable: foo") do
      interpreter.interpret("foo = 15", "test")
    end

    result = interpreter.interpret("char[] word = ['h', 'e', 'l', 'l', 'o']", "test")
    result.should be_a Array(ValueType)
    result.as(Array(ValueType)).join.should eq "hello"

    result = interpreter.interpret("int[][] matrix = [[1,2,3], [4,5,6]]", "test")
    result.should be_a Array(ValueType)
    matrix = result.as Array(ValueType)
    matrix[0].should be_a Array(ValueType)
    matrix[1].should be_a Array(ValueType)

    sum = 0
    matrix[0].as(Array(ValueType)).each { |v| sum += v.as Int64 }
    matrix[1].as(Array(ValueType)).each { |v| sum += v.as Int64 }
    sum.should eq 21

    result = interpreter.interpret("any->bool valids = {yes -> true, [123] -> false}", "test")
    result.should eq ({"yes" => true, 123 => false})

    # no 'Range' typedef yet
    result = interpreter.interpret("any my_range = 1..16", "test")
    result.should eq 1..16
  end
  it "interprets type aliases" do
    result = interpreter.interpret("type MyInt = int; MyInt my_int = 123", "test")
    result.should eq 123
  end
  it "interprets variable assignments" do
    interpreter.interpret("int x = 0b11", "test")
    result = interpreter.interpret("x = 5", "test")
    result.should eq 5
    result = interpreter.interpret("x = 12", "test")
    result.should eq 12
  end
  it "interprets compound assignment" do
    result = interpreter.interpret("int a = 5", "test")
    result.should eq 5
    result = interpreter.interpret("a += 2", "test")
    result.should eq 7
    result = interpreter.interpret("a -= 17", "test")
    result.should eq -10
    result = interpreter.interpret("a *= 4", "test")
    result.should eq -40
  end
  it "interprets function definitions" do
    result = interpreter.interpret("bool fn is_eq(int a = 5, int b) { return a == b }", "test")
    result.should be_a Callable
    result.should be_a Function

    result = interpreter.interpret("float fn half_sum(int a, int b) { (a + b) / 2 }", "test")
    result.should be_a Callable
    result.should be_a Function
  end
  it "interprets function calls" do
    result = interpreter.interpret("is_eq == none", "test")
    result.should be_false
    result = interpreter.interpret("is_eq(1, 1)", "test")
    result.should be_true
    result = interpreter.interpret("is_eq(none, 5)", "test")
    result.should be_true
    result = interpreter.interpret("is_eq(1, 2)", "test")
    result.should be_false

    result = interpreter.interpret("half_sum(9, 7) + 2", "test")
    result.should eq 10
  end
  it "interprets string concatenation" do
    interpreter.interpret("string msg = \"\"", "test")
    interpreter.interpret("msg += \"hello\"", "test")
    result = interpreter.interpret("msg + \" world\"", "test")
    result.should eq "hello world"
  end
  describe "interprets indexing" do
    it "strings" do
      interpreter.interpret("string word = \"hey\"", "test")
      result = interpreter.interpret("word[0]", "test")
      result.should eq 'h'
      result = interpreter.interpret("word[1]", "test")
      result.should eq 'e'
      result = interpreter.interpret("word[2]", "test")
      result.should eq 'y'
    end
    it "vectors" do
      interpreter.interpret("int[] x = [1, 2]", "test")
      result = interpreter.interpret("x[0]", "test")
      result.should eq 1
      result = interpreter.interpret("x[1]", "test")
      result.should eq 2
    end
    it "tables" do
      interpreter.interpret("string->bool bad_people = {[\"billy bob\"] -> false, mj -> true, joemar -> false}", "test")
      result = interpreter.interpret("bad_people[\"billy bob\"]", "test")
      result.should eq false
      result = interpreter.interpret("bad_people.mj", "test")
      result.should eq true
      result = interpreter.interpret("bad_people::mj", "test")
      result.should eq true
      result = interpreter.interpret("bad_people->joemar", "test")
      result.should eq false
    end
  end
  it "interprets if/unless statements" do
    lines = [
      "int x = 5",
      "int doubled",
      "if x == 5 {",
      " doubled = x * 2",
      "} else {",
      " doubled = x",
      "}",
      "doubled"
    ]

    result = interpreter.interpret(lines.join('\n'), "test")
    result.should eq 10

    lines = [
      "int x = 5",
      "int doubled",
      "unless x == 5 {",
      " doubled = x * 2",
      "} else {",
      " doubled = x",
      "}",
      "doubled"
    ]

    result = interpreter.interpret(lines.join('\n'), "test")
    result.should eq 5
  end
  it "interprets while/until statements" do
    lines = [
      "int x = 0",
      "while x < 10 {",
      " x += 1",
      "}",
      "x"
    ]

    result = interpreter.interpret(lines.join('\n'), "test")
    result.should eq 10

    lines = [
      "int x = 0",
      "until x == 15 {",
      " x += 1",
      "}",
      "x"
    ]

    result = interpreter.interpret(lines.join('\n'), "test")
    result.should eq 15
  end
  it "interprets every statements" do
    lines = [
      "int[] nums = [1,2,3]",
      "int sum = 0",
      "every int n in nums {",
      " sum += n",
      "}",
      "sum"
    ]

    result = interpreter.interpret(lines.join('\n'), "test")
    result.should eq 6
  end
  it "throws when types mismatch" do
    interpreter.interpret("int x = 1", "test")
    expect_raises(Exception, "[1:2] Type mismatch: Expected 'int', got 'float'") do
      interpreter.interpret("x = 2.0", "test")
    end
    expect_raises(Exception, "[1:3] Invalid '+' operand type: Char") do
      interpreter.interpret("x + 'h'", "test")
    end
    expect_raises(Exception, "[1:6] Type mismatch: Expected 'float', got 'int'") do
      interpreter.interpret("float[] aba = [x, 2.0]", "test")
    end
  end
  describe "interprets examples: " do
    example_files = Dir.entries "examples/"
    example_files.each do |example_file|
      next if example_file.starts_with?(".")
      it example_file do
        interpreter = Interpreter.new(output_ast: false, run_benchmarks: false, debug_mode: true)
        path = File.join "examples", example_file
        source = File.read(path)
        shutup do
          interpreter.interpret(source, "test")
        end
      end
    end
  end
end
