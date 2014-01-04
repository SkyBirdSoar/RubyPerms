require File.join(File.expand_path(File.dirname(__FILE__)), 'IPermission')
class Permission < IPermission
  def initialize(permission, ext = false)
    return if handle_init(permission)
    case permission
    when String
      @negated = permission.start_with?(?-)
      @permission = negated ? permission.sub(?-, '') : permission
      fail("Invalid permission string") unless self.valid?(@permission)
      @length = permission.split(?.).length
      if ext
        require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionExtension')
        extend PermissionExtension
      end
    when kind_of?(Permission)
      @negated = permission.negated
      @permission = permission.permission
      @length = permission.length
    else
      raise TypeError, "Failed to initialize #{self.name} with unknown class: #{permission.class}"
    end
    after_init
  end

  def self.valid?(permission)
    !permission.end_with?(?*)
  end

  def handle_init(permission)
    # if ClusterRegistrar.has_cluster(permission)
    false
  end

  def after_init
    # PermissionRegistrar.register_permission(permission)
  end
end
