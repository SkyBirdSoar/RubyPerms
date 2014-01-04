require File.join(File.expand_path(File.dirname(__FILE__)), 'Negatable')
require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
module PermissionExtension
  include Negatable
  include Enumerable
  include Comparable
  def broaden(depth = 1)
  	case depth
    when 0
      nil
    when 1
      temp = @permission.chomp(".#{@nodes ||= @permission.split(?.)[-1]}") << ".*"
      temp = WildPermission.new(temp)
      temp.negated = @negated
      temp
    else
      @nodes ||= @permission.split(?.)
      nodes = Array.new(@nodes)
      if depth < nodes.length
        depth.times { |no_of_times| nodes.slice!(-1) }
        nodes << ?*
        temp = nodes.join(?.)
        temp = WildPermission.new(temp)
        temp.negated = @negated
        temp
      else
        nil
      end
    end
  end
  alias_method :expand, :broaden

  def each(&block)
    @nodes ||= @permission.split(?.)
    if block_given?
      @nodes.each do |node|
        block.call node
      end
    else
      @nodes.to_enum
    end
  end

  def <=>(object)
    case object
    when String
      @permission <=> object
    when Permission
      if @permission == object.permission
        if @negated == object.negated
          0
        else
          @negated ? -1 : 1
        end
      else
        case
        when @negated && object.negated
          @permission <=> object.permission
        when @negated && !object.negated
          -1
        when !@negated && !object.negated
          @permission <=> object.permission
        when !@negated && object.negated
          1
        end
      end
    when PermissionGroup
      case
      when @negated && object.negated
        -1
      when @negated && !object.negated
        -1
      when !@negated && !object.negated
        -1
      when !@negated && object.negated
        1
      end
    else
      nil
    end
  end
end
