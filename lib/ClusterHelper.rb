require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'WildHelper')
class ClusterHelper
  def self.add_child(cluster, child)
    unless self.has_child?(cluster, child)
      begin
        child = Permission.new(child).negated = x.negated
      rescue RuntimeError
        child = WildPermission.new(child) = x.negated
      end
      cluster.children << child
    end
  end

  def self.add_child!(cluster, child)
    begin
      child = Permission.new(child)
    rescue RuntimeError
      child = WildPermission.new(child)
    end
    cluster.children << child
  end

  def self.remove_child(cluster, child, deep = false)
    cluster.children.delete_if do |x|
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

  def self.get_child(cluster, child, deep = false)
    cluster.children.select do |x|
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

  def self.has_child?(cluster, child, deep = false)
    permissions = self.get_child(cluster, child, deep)
    len, c_child = 0, nil
    permissions.each do |per|
      if per.length > len
        len, c_child = per.length, per
      end
    end
    c_child.nil? ? false : c_child.negated
  end
end
