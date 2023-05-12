require "./syntax_type"
require "./syntax_type"
require "./parser/ast"

class Cosmo::Parser
  getter source : String

  def initialize(@source)
  end

  def parse : Node
  end
end
