require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'WildHelper')
module ClusterExtension
  def add_child(child)
    unless has_child?(child)
      begin
        child = Permission.new(child).negated = x.negated
      rescue RuntimeError
        child = WildPermission.new(child) = x.negated
      end
      @children << child
    end
  end

  def add_child!(child)
    begin
      child = Permission.new(child)
    rescue RuntimeError
      child = WildPermission.new(child)
    end
    @children << child
  end

  def remove_child(child, deep = false)
    @children.delete_if do |x|
      if x.kind_of? WildPermission
        if deep
          if x.respond_to?(:include?)
            x.permission == child || x.include?(child)
          else
            x.permission == child || WildHelper.include?(x, child)
          end
        else
          x.permission == child
        end
      else
        x.permission == child
      end
    end
  end

  def get_child(cluster, child, deep = false)
    @children.select do |x|
      if x.kind_of? WildPermission
        if deep
          if x.respond_to?(:include?)
            x.permission == child || x.include?(child)
          else
            x.permission == child || WildHelper.include?(x, child)
          end
        else
          x.permission == child
        end
      else
        x.permission == child
      end
    end
  end

  def has_child?(child, deep = false)
    permissions = get_child(child, deep)
    permissions.empty? ? false : @negated
  end
end
