require "./syntax_type"
require "./syntax_type"
require "./parser/ast"

class Parser
  getter source : String

  def initialize(@source)
  end

  def parse : Node
  end
end
