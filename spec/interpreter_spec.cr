require "./spec_helper"

describe Interpreter do
  interpreter = Interpreter.new(output_ast: false)
  it "interprets literals" do
    result = interpreter.interpret("false", "test")
    result.should be_false
    result = interpreter.interpret("true", "test")
    result.should be_true
    result = interpreter.interpret("123", "test")
    result.should eq 123
    result = interpreter.interpret("0b111", "test")
    result.should eq 7
    result = interpreter.interpret("0xabc", "test")
    result.should eq 2748
    result = interpreter.interpret("10.24335", "test")
    result.should eq 10.24335
    result = interpreter.interpret("\"hello\"", "test")
    result.should eq "hello"
    result = interpreter.interpret("'e'", "test")
    result.should eq 'e'
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
  it "interprets biary operators" do
    result = interpreter.interpret("3 * 6 / 2 - 9", "test")
    result.should eq 0
    result = interpreter.interpret("9 ^ 2 / 14 + 6 * 2", "test")
    result.should eq 17.785714285714285
  end
end
