class Logger
  def self.report_error(error_type : String, message : String, pos : UInt32, line : UInt32) : Exception
    raise "[#{line}:#{pos + 1}] #{error_type}: #{message}"
  end
end
