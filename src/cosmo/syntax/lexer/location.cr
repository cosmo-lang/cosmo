class Location
  include Comparable(self)

  getter line : UInt
  getter position : UInt
  getter file_name : (String | VirtualFile)?

  def initialize(@file_name, @line, @column)
  end

  def between?(min, max)
    return false unless min && max
    min <= self && self <= max
  end

  def directory
    original_file_name.try { |file_name| File.dirname(file_name) }
  end

  # Returns the Location as a string
  def expanded_location
    case @file_name
    when String
      self
    when VirtualFile
      @file_name.expanded_location.try &.expanded_location
    else
      nil
    end
  end

  # Returns the filename of the `expanded_location`
  def original_filename
    expanded_location.try &.filename.as?(String)
  end

  def to_s
    "#{@file_name}:#{@line}:#{position}"
  end
end
