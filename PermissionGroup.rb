require './plugins/ExtensionManager/Permissions/Permission'
require './plugins/ExtensionManager/Permissions/PermissionUtils'

require './plugins/ExtensionManager/Exceptions/InvalidPermissionGroupError'
require './plugins/ExtensionManager/Exceptions/NodeIndexOutOfBoundsError'
require './plugins/ExtensionManager/Exceptions/InvalidComparisonError'

# The Permission Class that accepts group nodes
#
# @example
#
#   perm = PermissionGroup.new('i.am.a.*')
#   #=> <PermissionGroup: Permission="i.am.a.*">
#
#   perm = Permission.new('i.am.very.sexy') # Use Permission
#   #=> InvalidPermissionGroupError
#
#   perm2 = 'i.am.a.*'.to_perm_group # Only works if core-string-permission-patch.rb is applied!
#   #=> <PermissionGroup Permission="i.am.a.*">
#
#   perm == perm2
#   #=> true
#
#   perm.included?('i.am.a.very.sexy.*')
#   #=> true
#
#   !perm
#   #=> <Permission = "-i.am.a.*">
#
#   perm.last # Gets the second last node.
#   #=> "a"
#
#   perm.each do |node|
#     puts node
#   end
#   #=> i|am|a|* # Treat | as a newline
#
#   perm.broaden # Accepts integers as depth too;
#   #=> <PermissionGroup: Permission="i.am.*">
#
#   perm[1]
#   #=> "am"
#
#   # More methods below
class PermissionGroup
  include Enumerable
  include Comparable
  # @!attribute [r] permission
  #   The permission string used to intantiate {PermissionGroup}
  # @!attribute [r] nodes
  #   An array of nodes
  attr_reader :permission, :nodes

  # Initializes self with a permissiongroup string
  # @param string [String] valid permission string
  # @raise InvalidPermissionGroupError if string is invalid
  def initialize(string)
    raise InvalidPermissionGroupError unless PermissionUtils.valid?(string, :PermissionGroup) # :P
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
  # - have multiple wildcards ('.*.')
  # - does not end with '.*''
  #
  # @return [Boolean]
  def self.valid?(string)
    case string
    when String
      if string.start_with?(?-)
        string = string.sub('-', '')
      end
      string.match(/\A[a-zA-Z].*/) && string.include?(?.) && !string.include?('..') && string.end_with?('.*') && !string.include?('.*.')
    when PermissionGroup
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
  #   !PermissionGroup.new('a.b.c.d.*')
  #   #=> <PermissionGroup: Permission="-a.b.c.d.*">
  #
  # @return [PermissionGroup] opposite of self
  def !
    negated? ? negate(false) : negate
  end

  # Compare if self is equal to object
  # @param object [PermissionGroup, String]
  #
  # @example
  #
  #   PermissionGroup.new('a.b.c.*') != 'a.b.c.*'
  #   #=> false
  #
  #   PermissionGroup.new('a.b.c.*') != 'c.d.e'
  #   #=> true
  #
  #   PermissionGroup.new('a.b.c.d.*') != 'a.b.c.d.e.f.*' # More than.
  #   #=> true
  #
  # @return [Integer]
  def !=(object)
    case object
    when PermissionGroup
      self != object
    when String
      self.permission != object.downcase
    else
      true
    end
  end

  # Compare self to object
  # @param object [PermissionGroup, String]
  #
  # @example
  #
  #   PermissionGroup.new('a.b.c.*') <=> 'a.b.c.*'
  #   #=> 0
  #
  #   PermissionGroup.new('a.b.c.*') <=> 'c.d.e' # Unknown
  #   #=> InvalidComparisonError
  #
  #   PermissionGroup.new('a.b.c.d.*') <=> 'a.b.c.d.e.f.*' # More than.
  #   #=> 1
  #
  # @return [Integer]
  def <=>(object)
    case object
    when PermissionGroup
      if first == object.first
        to_a.length <=> object.to_a.length
      else
        raise InvalidComparisonError
      end
    when String
      raise InvalidPermissionGroupError unless object.downcase.end_with?('.*')
      object = object.downcase.split(?.)
      if first == object.first
        to_a.length <=> object.to_a.length
      else
        0 # Unknown
      end
    else
      raise InvalidComparisonError
    end
  end

  # Compare if self is equal to object
  # @param object [PermissionGroup, String]
  #
  # @example
  #
  #   PermissionGroup.new('a.b.c.*') == 'a.b.c.*'
  #   #=> true
  #
  #   PermissionGroup.new('a.b.c.*') == 'c.d.e'
  #   #=> false
  #
  #   PermissionGroup.new('a.b.c.d.*') == 'a.b.c.d.e.f.*' # More than.
  #   #=> false
  #
  # @return [Integer]
  def ==(object)
    case object
    when PermissionGroup
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
  #   PermissionGroup.new('a.b.c.*')[1]
  #   #=> "b"
  #
  # @return [String] The node at index
  def [](index)
    to_a[index]
  end

  # Removes the last (depth) nodes then subs
  # the new last node with ".*"
  # @param depth [Integer]
  # @return [PermissionGroup] Broadened @permission.
  def broaden(depth = 1)
    if depth == 1
      temp = @permission.chomp(".#{last}.*")
      temp = temp + ".*"
      PermissionGroup.new(temp)
    else
      depth = depth + 1
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

  # Removes the last (depth) nodes then subs
  # the new last node with ".*"
  # @param depth [Integer]
  # @return [self] with broadened @permission.
  # @note self is modified in place.
  def broaden!(depth = 1)
    if depth == 1
      temp = @permission.chomp(".#{last}.*")
      temp = temp + ".*"
      PermissionGroup.new(temp)
    else
      depth = depth + 1
      if depth < to_a.length
        depth.times do |no_of_times|
          @nodes.slice!(-1)
        end
        @nodes << '*'
        self
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

  # Check if a permission is included in self
  #
  # @param string [Permission, String] String to check against
  # @return [Boolean] on whether string is included in self
  # @return [nil] if string is not valid
  def include?(string)
    case string
    when Permission
      PermissionUtils.include?(string.permission, @permission)
    when String
      PermissionUtils.include?(string, @permission)
    else
      nil
    end
  end

  def inspect
    "#<PermissionGroup:0x#{'%x' % (self.object_id << 1)} Permission=#{@permission.inspect}>"
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
  # @return [PermissionGroup] opposite of self
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
  # @param object [PermissionGroup, String, Array] the object to match
  # 
  # @example
  #   PermissionGroup.new('a.b.c.d').match(['a', 'b', 'c', '6'])
  #   #=> ['a', 'b', 'c']
  #
  # @return [Array] when object is an Array or PermissionGroup
  # @return [Boolean] when object is a String
  # @return [nil] when object is not PermissionGroup, String, or Array
  def match(object)
    case object
    when PermissionGroup
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
    @nodes[-2]
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
      PermissionGroup.new("-#{@permission}")
    when false
      return self unless negated?
      PermissionGroup.new(@permission.sub('-', ''))
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
