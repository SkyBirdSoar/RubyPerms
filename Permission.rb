require './plugins/ExtensionManager/Permissions/PermissionGroup'
require './plugins/ExtensionManager/Permissions/PermissionUtils'

require './plugins/ExtensionManager/Exceptions/InvalidPermissionError'
require './plugins/ExtensionManager/Exceptions/NodeIndexOutOfBoundsError'

# The permission class which does *most* of the work regarding
# permissions
#
# @example
#
#   perm = Permission.new('i.am.a.very.sexy.permission!')
#   #=> <Permission = "i.am.a.very.sexy.permission!">
#
#   perm = Permission.new('i.am.a.very.sexy.*') # Use PermissionGroup
#   #=> InvalidPermissionError
#
#   perm2 = 'i.am.a.very.sexy.permission!'.to_perm # Only works if core-string-permission-patch.rb is applied!
#   #=> <Permission = "i.am.a.very.sexy.permission!">
#
#   perm == perm2
#   #=> true
#
#   perm.included?('i.am.a.very.sexy.*')
#   #=> true
#
#   !perm
#   #=> <Permission = "-i.am.a.very.sexy.permission!">
#
#   perm.last # perm.first works too
#   #=> "permission!"
#
#   perm.each do |node|
#     puts node
#   end
#   #=> i|am|a|very|sexy|permission! # Treat | as a newline
#
#   perm.broaden # Accepts integers as depth too;
#   #=> <PermissionGroup: Permission="i.am.a.very.*">
#
#   perm[1]
#   #=> "am"
#
#   # More methods below
class Permission
  include Enumerable
  # @!attribute [r] permission
  #   The permission string used to intantiate {Permission}
  # @!attribute [r] nodes
  #   An array of nodes
  attr_reader :permission, :nodes

  # Initializes self with a permission string
  # @param string [String] valid permission string
  # @raise InvalidPermissionError if string is invalid
  def initialize(string)
    raise InvalidPermissionError unless PermissionUtils.valid?(string, :Permission) # :P
    @permission = string.downcase
    @nodes = to_a
  end

  # Check if a string is valid
  #
  # @param string The string to validate
  #
  # Examples of invalid strings are:
  # - first character not beginning with an alphabet
  # - does not include a '.'
  # - have 2 or more consecutive '.' like 'a..b.c'
  # - ends with a '.'
  # - ends with '.*' ({PermissionGroup})
  #
  # @return [Boolean]
  def self.valid?(string)
    case string
    when String
      if string.start_with?(?-)
        string = string.sub('-', '')
      end
      string.match(/\A[a-zA-Z].*/) && string.include?(?.) && !string.include?('..') && !string.end_with?(?.) && !string.end_with?('.*')
    when Permission
      true
    else
      false
    end
  end

  # Returns an un-negated self object if
  # @permission is negated. Returns a negated self
  # object if @permission is not-negated.
  #
  # @example
  #   !Permission.new('a.b.c.d.e')
  #   #=> <Permission = "-a.b.c.d.e">
  #
  # @return [Permission] opposite of self
  def !
    negated? ? negate(false) : negate
  end

  # Check if self != object
  # Check if self.permission != object
  # @param object [Permission, String]
  #
  # @example
  #   Permission.new('a.b.c') != Permission.new('a.b')
  #   #=> true
  #
  #   Permission.new('a.b.c') != 'a.b.c'
  #   #=> false
  #
  # @return [Boolean]
  def !=(object)
    case object
    when Permission
      self != object
    when String
      self.permission != object.downcase
    else
      true
    end
  end

  # Compare self to object
  # @param object [Permission, String]
  #
  # @example
  #
  #   Permission.new('a.b.c') <=> 'a.b.c'
  #   #=> 0
  #
  # @return [Integer]
  def <=>(object)
    case object
    when Permission
      self.permission <=> object.permission
    when String
      self.permission <=> object.downcase
    else
      -1
    end
  end

  # Check if self == object
  # Check if self.permission == object
  # @param object [Permission, String]
  #
  # @example
  #   Permission.new('a.b.c.d') == 'a.b.c.d'
  #   #=> true
  #
  # @return [Boolean]
  def ==(object)
    case object
    when Permission
      self.permission == object.permission
    when String
      self.permission == object.downcase
    else
      false
    end
  end

  # Get the node at index
  # @param index [Integer]
  #
  # @example
  #   Permission.new('a.b.c')[1]
  #   #=> "b"
  #
  # @return [String] The node at index
  def [](index)
    to_a[index]
  end

  # Removes the last (depth - 1) nodes then subs
  # the new last node with ".*"
  # @param depth [Integer]
  # @return [PermissionGroup] Broadened @permission.
  def broaden(depth = 1)
    if depth == 1
      temp = @permission.chomp(".#{last}")
      temp = temp + ".*"
      PermissionGroup.new(temp)
    else
      if depth < to_a.length
        nodes = @permission.split(?.)
        depth.times do |no_of_times|
          nodes.slice!(-1)
        end
        nodes << '*'
        PermissionGroup.new(nodes.join('.'))
      else
        raise NodeIndexOutOfBoundsError, "Depth is >= length"
      end
    end
  end

  # Iterate through the nodes
  # @yield nodes
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

  # Check if @permission is included in PermissionGroup
  #
  # @param group [PermissionGroup, String] Group to check against
  # @return [Boolean] on whether @permission is included in PermissionGroup
  # @return [nil] if group is not valid
  # @see PermissionGroup#include?
  def included?(group)
    case group
    when PermissionGroup
      PermissionUtils.include?(@permission, group.permission)
    when String
      PermissionUtils.include?(@permission, group)
    else
      nil
    end
  end

  def inspect
    "#<Permission:0x#{'%x' % (self.object_id << 1)} = #{@permission.inspect}>"
  end

  # Returns a symbol version of @permission
  # @return [Symbol] @permission
  def intern
    @permission.intern
  end

  alias_method :to_sym, :intern
  alias_method :to_symbol, :intern

  # Returns !self
  #
  # @return [Permission] opposite of self
  def inverse
    !self
  end

  # Returns !self
  #
  # @return [self] opposite of self
  # @note self will be modified in place.
  def inverse!
    @permission = (!self).permission
    @nodes = @permission.split(?.)
    self
  end

  # Match self to object
  # @param object [Permission, String, Array] the object to match
  # 
  # @example
  #   Permission.new('a.b.c.d').match(['a', 'b', 'c', '6'])
  #   #=> ['a', 'b', 'c']
  #
  # @return [Array] when object is an Array or Permission
  # @return [Boolean] when object is a String
  # @return [nil] when object is not Permission, String, or Array
  def match(object)
    case object
    when Permission
      @nodes & object.nodes
    when String
      self.permission == object.downcase
    when Array
      @nodes & object
    else
      nil
    end
  end

  # Get the last node
  # @return [String] the last node
  def last
    @nodes.last
  end

  # Get the first node
  # @return [String] the first node
  def max
    first
  end

  # Get the last node
  # @return [String] the last node
  def min
    last
  end

  # @return [Boolean] on whether self is negated
  def negated?
    return true if @permission.start_with?(?-)
    false
  end

  # @param negate [Boolean]
  # @return [Permission] permission if negate = false
  # @return [Permission] -permission if negate = true
  def negate(negate = true)
    case negate
    when true
      return self if negated?
      Permission.new("-#{@permission}")
    when false
      return self unless negated?
      Permission.new(@permission.sub('-', ''))
    end
  end

  # @param negate [Boolean]
  # @return [self] permission if negate = false
  # @return [self] -permission if negate = true
  # @note self will be modified in place
  def negate!(negate = true)
    case negate
    when true
      return self if negated?
      @permission.prepend('-')
      self
    when false
      return self unless negated?
      @permission.sub!('-', '')
      self
    end
  end

  # You shouldn't sort the nodes ._.
  # They are in order.
  # @return [Array<String>]
  def sort
    to_a
  end

  def to_s
    @permission
  end

  def to_str
    @permission
  end
end
