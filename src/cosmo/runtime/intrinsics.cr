MAX_INTRINSIC_PARAMS = 255

abstract class Cosmo::IntrinsicFunction < Cosmo::Callable
  abstract def call(args : Array(ValueType)) : ValueType

  def intrinsic? : Bool
    true
  end

  def to_s : String
    "<intrinsic ##{self.hash}>"
  end
end

class Cosmo::PutsIntrinsic < Cosmo::IntrinsicFunction
  def arity : Range(UInt32, UInt32)
    1.to_u .. MAX_INTRINSIC_PARAMS.to_u
  end

  def call(args : Array(ValueType)) : Nil
    puts args.map(&.to_s).join('\t')
  end
end
