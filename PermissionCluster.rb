require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionGroup')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionUtils')
require File.join(File.expand_path(File.dirname(__FILE__)), 'Permissible')

# Adds the ability for child permissions.
# Warning, all child permissions share the same @negated.
class PermissionCluster
  include Enumerable

  # @!attribute [r] permission
  #   The permission to be identified as
  # @!attribute [r] children
  #   Child permissions
  # @!attribute [r] negated
  #   true if negated, false otherwise.
  attr_reader :permission, :children, :negated
  def initialize(string, children)
    case string
    when String
      fail("Invalid permission string.") if string.end_with?(?*) || string.include?('..')
      @negated = PermissionUtils.negated?(string)
      @permission = @negated ? string.sub('-', '') : string
      @children = []
      add_child(children)
    when PermissionCluster
      @permission = String.new(string.permission)
      @negated = string.negated
      @children = Array.new(string.children)
      add_child(children)
    else
      fail(TypeError, "Unknown type.")
    end
  end

  # @param children [String, Permission, PermissionGroup, PermissionCluster, Permissible, Array<String, Permission, PermissionGroup, PermissionCluster, Permissible>]
  # @param clear [Boolean] Reset @children before adding.
  # @return [Boolean]
  def add_child(children, clear = false)
    case children
    when String
      begin
        p = PermissionUtils.create(children)
        p.negate!(@negated)
        @children << p
        true
      rescue RuntimeError
        false
      end
    when Permission || PermissionGroup
      children.negate!(@negated)
      @children << children
      true
    when PermissionCluster
      children.negate!(@negated)
      if clear
        @children = children.children
      else
        @children << children.children
      end
      true
    when Permissible || Array
      # WHY SUPPORT THIS BULK OF PERMISSIONS ._.
      @children.clear if clear
      children.each do |x| 
        add_child(x)
      end
    end
  end

  # @param children [String, Permission, PermissionGroup, PermissionCluster, Permissible, Array<String, Permission, PermissionGroup, PermissionCluster, Permissible>]
  def remove_child(children)
    case children
    when String
      @children.delete_if { |x| x.permission = children }
    when Permission || PermissionGroup
      remove_child(children.permission)
    when PermissionCluster || Array || Permissible
      children.each { |x| remove_child(x.permission) }
    end
  end

  # @param child [String, Permission, PermissionGroup]
  # @return [Boolean]
  def has_child?(child)
    case child
    when String
      @children.any? do |x|
        case x
        when Permission
          x == child
        when PermissionGroup
          x == child || x.include?(child)
        end
      end
    when Permission || PermissionGroup
      has_child?(child.permission)
    else
      false
    end
  end

  # Creates a new PermissionCluster object with the same permission
  # and children with @negated as true/false
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [PermissionCluster] A new PermissionCluster object.
  def negate(negate = true)
    case negate
    when true
      return self if @negated
      PermissionCluster.new("-#{@permission}", @children)
    when false
      return self unless @negated
      PermissionCluster.new(@permission, @children)
    end
  end

  # Set @negated for self & children
  #
  # @param negate [Boolean] boolean to set @negated
  # @return [PermissionCluster] A new PermissionCluster object.
  def negate!(negate = true)
    @negate = negate
    @children.each { |x| x.negate!(@negate) }
    self
  end

  # Calls block for each node in permission.
  # @yield [String] a node in permission.
  # @return [Enumerator] if block wasn't given.
  def each(&block)
    if block_given?
      @children.each do |node|
        block.call node
      end
    else
      @children.to_enum
    end
  end

  # @return [Boolean]
  def empty?
    @children.empty?
  end

  def inspect
    "#<PermissionCluster:0x#{'%x' % (self.object_id << 1)} Permission=#{@permission.inspect} negated=#{@negated.inspect} Children=#{@children.length}>"
  end

  # @return [PermissionCluster] A new PermissionCluster object with !@negated
  def !
    @negated ? PermissionCluster.new(@permission, @children) : Permission.new("-#{@permission}", @children)
  end
  alias_method :inverse, :'!'

  # Inverts @negated.
  # @return [self]
  def inverse!
    negate!(!@negated)
  end

  def to_str
    @negated ? "-#{@permission}" : @permission
  end
end
