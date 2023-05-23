class Cosmo::Type
  getter name : String

  def initialize(@name)
  end

  def to_s
    "Type<#{name}>"
  end
end
