require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionUtils')

# Adds extra methods along with Permission methods for dealing with wildcards
class PermissionGroup
  include Enumerable
  include Comparable

  # @!attribute [r] permission
  #   The permission that was given during init
  # @!attribute [r] nodes
  #   permission split on '.'
  # @!attribute [r] negated
  #   true if the permission is negated, false otherwise.
  attr_reader :permission, :nodes, :negated

  # @param string [String, PermissionGroup] The permission this PermissionGroup instance should have.
  def initialize(string)
    case string
    when String
      fail("Invalid permission string.") if !string.end_with?(?*) || string.include?('..') || string.include?('.*.')
      string = string.downcase
      @negated = PermissionUtils.negated?(string)
      @permission = @negated ? string.sub('-', '') : string
      @nodes = to_a
    when PermissionGroup
      @permission = String.new(string.permission)
      @nodes = Array.new(string.nodes)
      @negated = string.negated
    else
      fail(TypeError, "Unknown type.")
    end
  end

  # @return [PermissionGroup] A new PermissionGroup object with !@negated
  def !
    @negated ? PermissionGroup.new(@permission) : PermissionGroup.new("-#{@permission}")
  end
  alias_method :inverse, :'!'

  # @param index [Integer]
  def [](index)
    @nodes[index]
  end

  # @param object [String, Permission, PermissionGroup] Object to compare.
  # @return [Integer]
  # @return [nil]
  def <=>(object)
    case object
    when String
      @permission <=> object
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
    when PermissionGroup
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
    else
      nil
    end
  end

  # Expands the last _depth_ nodes
  # @example
  #   PermissionGroup.new('a.b.c.d.*').broaden
  #   #=> #<PermissionGroup:0x423a4f Permission="a.b.c.*" negated=false>
  #
  # @param depth [Integer] The level to expand.
  # @return [PermissionGroup] The broadened PermissionGroup
  def broaden(depth = 1)
    perm = @permission.chomp('.*')
    if depth == 1
      temp = perm.chomp(".#{@nodes[-2]}")
      temp << ".*"
      if @negated
        temp = "-#{temp}"
      end
      PermissionGroup.new(temp)
    else
      if depth < @nodes.length
        nodes = perm.split(?.)
        depth.times do |no_of_times|
          nodes.slice!(-1)
        end
        nodes << '*'
        temp = nodes.join('.')
        if @negated
          temp = "-#{temp}"
        end
        PermissionGroup.new(temp)
      else
        nil
      end
    end
  end
  alias_method :expand, :broaden

  # Expands the last _depth_ nodes
  # @example
  #   PermissionGroup.new('a.b.c.d.*').broaden
  #   #=> #<PermissionGroup:0x423a4f Permission="a.b.c.*" negated=false>
  #
  # @param depth [Integer] The level to expand.
  # @return [self]
  def broaden!(depth = 1)
    perm = @permission.chomp('.*')
    if depth == 1
      @permission = perm.chomp(".#{@nodes[-2]}") << '.*'
      self
    else
      if depth < @nodes.length
        nodes = perm.split(?.)
        depth.times do |no_of_times|
          nodes.slice!(-1)
        end
        nodes << '*'
        @permission = nodes.join('.')
        self
      else
        nil
      end
    end
  end
  alias_method :expand, :broaden

  # Calls block for each node in permission.
  # @yield [String] a node in permission.
  # @return [Enumerator] if block wasn't given.
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

  # Check if a string is included in self.
  # @param string [String, Permission, PermissionGroup]
  # @return [Boolean]
  # @return [nil]
  def include?(string)
    case string
    when String
      return false if string == @permission.chomp('.*')
      negated = PermissionUtils.negated?(string)
      case
      when @negated && negated
        string.include?(@permission.chomp('.*')) && string.start_with?(@nodes[0])
      when !@negated && !negated
        string.include?(@permission.chomp('.*')) && string.start_with?(@nodes[0])
      when @negated && !negated
        false
      when !@negated && negated
        false
      else
        nil
      end
    when Permission
      include?(string.permission)
    when PermissionGroup
      include?(string.permission.chomp('.*'))
    else
      nil
    end
  end

  def inspect
    "#<PermissionGroup:0x#{'%x' % (self.object_id << 1)} Permission=#{@permission.inspect} negated=#{@negated.inspect}>"
  end

  # Inverts @negated.
  # @return [self]
  def inverse!
    @negated = !@negated
    self
  end

  # Creates a new PermissionGroup object with the same permission
  # with @negated as true/false
  # @example
  #   PermissionGroup.new('-a.b.c.d.*').negate(false)
  #   #=> #<PermissionGroup:0x2b43a Permission="a.b.c.d.*" negated=false>
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [PermissionGroup] A PermissionGroup object.
  def negate(negate = true)
    case negate
    when true
      return self if @negated
      PermissionGroup.new("-#{@permission}")
    when false
      return self unless @negated
      PermissionGroup.new(@permission)
    end
  end

  # Sets @negated
  # @example
  #   PermissionGroup.new('-a.b.c.d').negate!(false)
  #   #=> #<Permission:0x2b43a Permission="a.b.c.d" negated=false>
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [self] self with @negated set to _negate_
  def negate!(negate = true)
    @negated = negate
    self
  end

  def to_str
    @negated ? "-#{@permission}" : @permission
  end

  def to_s
    to_str
  end
end
