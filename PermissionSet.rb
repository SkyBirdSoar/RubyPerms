require File.join(File.expand_path(File.dirname(__FILE__)), 'Permissible')

# Standard collection of Permission(s) and/or PermissionGroup(s)
class PermissionSet
  include Permissible

  def initialize(permissions)
    super(permissions)
    @listeners = []
  end

  def listen(instance)
    @listeners << instance
  end

  def update(event, info)
    @listeners.each { |x| x.notify(event, info) }
  end
end
