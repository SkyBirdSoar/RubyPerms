require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
class PermissionCluster < Permission
  attr_accessor :children
  def initialize(permission, children, ext = false)
    return if handle_init(permission)
    case permission
    when String
      @negated = permission.start_with?(?-)
      @permission = negated ? permission.sub(?-, '') : permission
      fail("Invalid permission string") unless self.valid?(@permission)
      @length = permission.split(?.).length
      case ext
      when true
        require File.join(File.expand_path(File.dirname(__FILE__)), 'ClusterExtension')
        extend ClusterExtension
        children.each do |child|
          add_child(child)
        end
      when false
        require File.join(File.expand_path(File.dirname(__FILE__)), 'ClusterHelper')
        helper = ClusterHelper.new
        children.each do |x|
          helper.add_child(x)
        end
      end
    when kind_of?(PermissionCluster)
      @negated = permission.negated
      @permission = permission.permission
      @length = permission.length
      @children = permission.children
    else
      raise TypeError, "Failed to initialize #{self.name} with unknown class: #{permission.class}"
    end
    after_init
  end

  def handle_init(permission)
    # if PermissionRegistrar.has_cluster(permission)
    false
  end

  def after_init
    # ClusterRegistrar.register_permission(permission)
  end
end
