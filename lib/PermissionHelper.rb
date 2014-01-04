require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
class PermissionHelper
  def self.broaden(permission, depth = 1)
    case depth
    when 0
      nil
    when 1
      temp = permission.permission.chomp(".#{permission.permission.split(?.)[-1]}") << ".*"
      temp = WildPermission.new(temp)
      temp.negated = permission.negated
      temp
    else
      nodes = permission.permission.split(?.)
      if depth < nodes.length
        depth.times { |no_of_times| nodes.slice!(-1) }
        nodes << ?*
        temp = nodes.join(?.)
        temp = WildPermission.new(temp)
        temp.negated = permission.negated
        temp
      else
        nil
      end
    end
  end
end
