require File.join(File.expand_path(File.dirname(__FILE__)), 'IPermission')
class WildPermission < IPermission
  def initialize(permission, ext = false)
    return if handle_init(permission)
    case permission
    when String
      @negated = permission.start_with?(?-)
      @permission = negated ? permission.sub(?-, '') : permission
      fail("Invalid permission string") unless self.valid?(@permission)
      @length = permission.split(?.).length
      if ext
        require File.join(File.expand_path(File.dirname(__FILE__)), 'WildExtension')
        extend WildExtension
      end
    when kind_of?(WildPermission)
      @negated = permission.negated
      @permission = permission.permission
      @length = permission.length
    else
      raise TypeError, "Failed to initialize #{self.name} with unknown class: #{permission.class}"
    end
    after_init
  end

  def self.valid?
    permission.end_with?(?*)
  end

  def after_init
    @length -= 1
  end
end
