module Negatable
  attr_reader :negated
  def negate(negate = true)
    t = self.class.new(@permission)
    t.negated = negate
    t
  end

  def negate!(negate = true)
    @negated = negate
  end

  def !
    negate(!@negated)
  end
  alias_method :inverse, :'!'

  def inverse!
    @negated = !@negated
  end
end
