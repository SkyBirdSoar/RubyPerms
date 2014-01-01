require File.join(File.expand_path(File.dirname(__FILE__)), 'Permissible')

# Standard collection of Permission(s) and/or PermissionGroup(s)
class PermissionSet
  include Permissible

  def initialize(name, permissions)
    super(permissions)
    @name = name
    @listeners = []
  end

  def listen(instance)
    @listeners << instance
  end

  def update(event, info)
    @listeners.each { |x| x.notify(event, info) }
  end

  def inspect
    "#<PermissionSet:0x#{'%x' % (self.object_id << 1)} Owner=#{@name} Permission_Count=#{@permissions.length}>"
  end

  def to_str
    @name
  end
end
