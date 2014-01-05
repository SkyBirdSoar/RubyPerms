require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'Negatable')
module WildExtension
  include Negatable
  include Enumerable
  include Comparable

  def [](index)
    @nodes ||= @permission.split(?.)
    @nodes[index]
  end

  def broaden(depth = 1)
    case depth
    when 0
      nil
    when 1
      temp = @permission.chomp(".#{@permission.split(?.)[-2]}.*") << ".*"
      temp = WildPermission.new(temp)
      temp.negated = permission.negated
      temp
    else
      nodes = @permission.split(?.)
      if depth < nodes.length
        depth += 1
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

  def broaden!(depth = 1)
    case depth
    when 0
      nil
    when 1
      temp = @permission.chomp(".#{(@nodes ||= @permission.split(?.))[-2]}.*") << ".*"
      @nodes = nodes
      self
    else
      @nodes ||= @permission.split(?.)
      nodes = Array.new(@nodes)
      if depth < nodes.length
        depth += 1
        depth.times { |no_of_times| nodes.slice!(-1) }
        nodes << ?*
        @permission = nodes.join(?.)
        @nodes = nodes
        self
      else
        nil
      end
    end
  end

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
    when WildPermission
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
    when Permission
      case
      when @negated && object.negated
        1
      when @negated && !object.negated
        -1
      when !@negated && !object.negated
        1
      when !@negated && object.negated
        1
      end
    else
      nil
    end
  end
end
