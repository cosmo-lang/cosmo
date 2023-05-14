enum FnType
  None
  Fn
end

class Cosmo::Resolver
  @scopes = [] of Hash(String, Bool)
  @current_fn = FnType::None

  def initialize(@interpreter : Interpreter)
  end

  def resolve(block : AST::Statement::Block)

  end
end
