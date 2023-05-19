class Cosmo::Location
  getter line : UInt32
  getter position : UInt32
  getter file_name : String

  def initialize(@file_name, @line, @position)
  end

  def between?(min : UInt32, max : UInt32)
    return false unless min && max
    min <= self && self <= max
  end

  def directory
    @file_name.try { |file_name| File.dirname(file_name) }
  end

  def to_s
    "#{@file_name}:#{@line}:#{position}"
  end
end
