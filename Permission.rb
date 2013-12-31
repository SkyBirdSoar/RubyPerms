require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionGroup')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionUtils')

# Permission class to manipulate permissions easily.
class Permission
  include Enumerable
  include Comparable

  # @!attribute [r] permission
  #   The permission that was given during init
  # @!attribute [r] nodes
  #   permission split on '.'
  # @!attribute [r] negated
  #   true if the permission is negated, false otherwise.
  attr_reader :permission, :nodes, :negated

  # @param string [String, Permission] The permission this Permission instance should have.
  def initialize(string)
    case string
    when String
      fail("Invalid permission string.") if string.end_with?(?*) || string.include?('..')
      string = string.downcase
      @negated = PermissionUtils.negated?(string)
      @permission = @negated ? string.sub('-', '') : string
      @nodes = to_a
    when Permission
      @permission = String.new(string.permission)
      @nodes = Array.new(string.nodes)
      @negated = string.negated
    else
      fail(TypeError, "Unknown type.")
    end
  end

  # @return [Permission] A new Permission object with !@negated
  def !
    @negated ? Permission.new(@permission) : Permission.new("-#{@permission}")
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
        1
      when !@negated && !object.negated
        -1
      when !@negated && object.negated
        -1
      end
    else
      nil
    end
  end

  # Expands the last _depth_ nodes
  # @example
  #   Permission.new('a.b.c.d').broaden
  #   #=> #<PermissionGroup:0x423a4f Permission="a.b.c.*" negated=false>
  #
  # @param depth [Integer] The level to expand.
  # @return [PermissionGroup] The broadened PermissionGroup
  def broaden(depth = 1)
    if depth == 1
      temp = @permission.chomp(".#{@nodes[-1]}")
      temp = temp + ".*"
      if @negated
        temp = "-#{temp}"
      end
      PermissionGroup.new(temp)
    else
      if depth < @nodes.length
        nodes = @permission.split(?.)
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

  def inspect
    "#<Permission:0x#{'%x' % (self.object_id << 1)} Permission=#{@permission.inspect} negated=#{@negated.inspect}>"
  end

  # Inverts @negated.
  # @return [self]
  def inverse!
    @negated = !@negated
    self
  end

  # Creates a new Permission object with the same permission
  # with @negated as true/false
  # @example
  #   Permission.new('-a.b.c.d').negate(false)
  #   #=> #<Permission:0x2b43a Permission="a.b.c.d" negated=false>
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [Permission] A new Permission object.
  def negate(negate = true)
    case negate
    when true
      return self if @negated
      Permission.new("-#{@permission}")
    when false
      return self unless @negated
      Permission.new(@permission)
    end
  end

  # Sets @negated
  # @example
  #   Permission.new('-a.b.c.d').negate(false)
  #   #=> #<Permission:0x2b43a Permission="a.b.c.d" negated=false>
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [self] self with !@negated
  def negate!(negate = true)
    @negated = negate
    self
  end

  def to_str
    @negated ? "-#{@permission}" : @permission
  end
end
