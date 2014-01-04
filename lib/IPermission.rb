class IPermission
  attr_reader :permission, :length
  attr_accessor :negated

  def initialize(permission)
    return if handle_init(permission)
    case permission
    when String
      @negated = permission.start_with?(?-)
      @permission = negated ? permission.sub(?-, '') : permission
      fail("Invalid permission string") unless self.valid?(@permission)
      @length = permission.split(?.).length
    when kind_of?(IPermission)
      @negated = permission.negated
      @permission = permission.permission
      @length = permission.length
    else
      raise TypeError, "Failed to initialize #{self.name} with unknown class: #{permission.class}"
    end
    after_init
  end

  def self.valid?(permission)
    true
  end

  def handle_init(permission)
    false
  end

  def after_init(); end
end
