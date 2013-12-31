require './plugins/ExtensionManager/Permissions/Permission'
require './plugins/ExtensionManager/Permissions/PermissionGroup'

# Utility class for handling permission strings.
# @author SkyBirdSoar
class PermissionUtils
  # Check if a string is a valid {Permission#valid? Permission} or {PermissionGroup#valid? PermissionGroup} string
  #
  # @param string [String] The string to check for validity
  # @param syntax [Symbol] Use :Permission to
  #   validate the string as a {Permission} string or :PermissionGroup
  #   for {PermissionGroup} Leave opts empty to check if its valid for
  #   either {Permission} or {PermissionGroup}
  #
  # @example
  #   PermissionUtils.valid?('a.b.c.d.e')
  #   #=> true
  #
  #   PermissionUtils.valid?('a.b.c.d.*')
  #   #=> true
  #
  #   PermissionUtils.valid?('a.b.c.d.*', :Permission)
  #   #=> false
  #
  #   PermissionUtils.valid?('a.b.c.d.e', :PermissionGroup)
  #   #=> false
  #
  #   PermissionUtils.valid?('a.b.c.d.e', :permission) # Has to be properly capitalized.
  #   #=> nil
  #
  # @return [Boolean] on whether string is a valid {Permission#valid? Permission}
  #   or {PermissionGroup#valid? PermissionGroup} string
  # @return [nil] if syntax is not :Permission or :PermissionGroup
  #
  # @see Permission
  # @see PermissionGroup
  def self.valid?(string, syntax = nil)
    if syntax == nil
      Permission.valid?(string) || PermissionGroup.valid?(string)
    else
      case syntax
      when :Permission || 'Permission'
        Permission.valid?(string)
      when :PermissionGroup || 'PermissionGroup'
        PermissionGroup.valid?(string)
      else
        nil
      end
    end
  end

  # Check if a string is a negated permission.
  #
  # @param string [String] The permission string to check.
  #
  # @example
  #   PermissionUtils.negated?('-a.b.c.d')
  #   #=> true
  #
  #   PermissionUtils.negated?('a.b.c.d')
  #   #=> false
  #
  #   PermissionUtils.negated?('a.b.c.*')
  #   #=> true
  #
  #   PermissionUtils.negated?('a')
  #   #=> nil
  #
  # @return [Boolean] on whether string is negated.
  # @return [nil] if string is not valid.
  #
  # @see valid?
  # @see allowed?
  def self.negated?(string)
    if self.valid?(string)
      return true if string.start_with?(?-)
      false
    else
      nil
    end
  end

  # Check if a string is a negated permission.
  #
  # @param string [String] The permission string to check.
  #
  # @example
  #   PermissionUtils.allowed?('-a.b.c.d')
  #   #=> false
  #
  #   PermissionUtils.allowed?('a.b.c.d')
  #   #=> true
  #
  #   PermissionUtils.allowed?('a.b.c.*')
  #   #=> true
  #
  #   PermissionUtils.allowed?('a')
  #   #=> nil
  #
  # @return [Boolean] on whether you should grant permission based on string.
  # @return [nil] if string is not valid.
  #
  # @see valid?
  # @see negated?
  def self.allowed?(string)
    if self.valid?(string)
      return false if string.start_with?(?-)
      true
    else
      nil
    end
  end

  # Returns a (negated) string
  #
  # @param string [String] The string to (un)negate.
  # @param negate [Boolean] true - negate |
  #                         false - unnegate
  #
  # @example
  #   PermissionUtils.negate('a.b.c.d')
  #   #=> "-a.b.c.d"
  #
  #   PermissionUtils.negate('a.b.c.d', false)
  #   #=> "a.b.c.d"
  #
  #   PermissionUtils.negate('-a.b.c.d', false)
  #   #=> "a.b.c.d"
  #
  # @return [String] the (negated) string
  # @return [nil] if string isn't valid
  #
  # @see valid?
  # @see negate!
  def self.negate(string, negate = true)
    if self.valid?(string)
      case negate
      when true
        return string if self.negated?(string)
        return "-#{string}"
      when false
        return string unless self.negated?(string)
        return string.sub('-', '')
      end
    else
      nil
    end
  end

  # Returns a (negated) string and modifies string in place
  #
  # @param string [String] The string to (un)negate.
  # @param negate [Boolean] true - negate |
  #                         false - unnegate
  #
  # @example
  #   string = 'a.b.c'
  #   #=> 'a.b.c'
  #
  #   PermissionUtils.negate!(string)
  #   #=> "-a.b.c"
  #
  #   string
  #   #=> '-a.b.c'
  #
  # @return [String] the (negated) string
  # @return [nil] if string isn't valid
  #
  # @see valid?
  # @see negate
  def self.negate!(string, negate = true)
    if self.valid?(string)
      case negate
      when true
        return string if self.negated?(string)
        return string.prepend('-')
      when false
        return string unless self.negated?(string)
        return string.sub!('-', '')
      end
    else
      nil
    end
  end

  # Check if a Permission string is included in a PermissionGroup
  #   string
  #
  # @param string [String] The Permission string to check
  # @param string_group [String] The PermissionGroup to check against
  #
  # @example
  #   PermissionUtils.include?('a.b.c.d.e', 'a.b.c.d.*')
  #   #=> true
  #
  #   PermissionUtils.include?('a.b.c.d.e', 'a.*')
  #   #=> true
  #
  #   PermissionUtils.include?('a.b.c.d.e', '-a.b.c.*')
  #   #=> false
  #
  # @return (Boolean) on whether string is included in string_group
  # @return (nil) if either string or string_group is invalid.
  #
  # @see valid?
  # @see compare
  def self.include?(string, string_group)
    if self.valid?(string, :Permission) && self.valid?(string_group, :PermissionGroup)
      return false if string == string_group.chomp('.*')
      nodes = string.split(?.)
      group_nodes = string_group.split(?.).each
      nodes.each do |node|
        begin
          group_node = group_nodes.next
          break if group_node != node
          return true if group_node == node && group_nodes.peek == '*'
        rescue StopIteration
          return false
        end
      end
      false
    else
      nil
    end
  end

  # Compare 2 strings (each can be Permission/PermissionGroup)
  #
  # @param string [String]
  # @param another_string [String]
  #
  # @example
  #   PermissionUtils.compare('a.b.c.d.e', 'a.b.c.d.*')
  #   #=> 0
  #
  #   PermissionUtils.compare('a.b.c.d.*', 'a.*')
  #   #=> 1
  #
  #   PermissionUtils.compare('a.*', 'a.b.c.d.*')
  #   #=> 1
  #
  #   PermissionUtils.compare('a.b.*', 'c.d.*')
  #   #=> -1
  #
  #   PermissionUtils.compare('a.b.*', 'a.b.*')
  #   #=> 0
  #
  # @return (Integer) on whether string is included in another_string
  #   |-1| - no match, |0| - exact match, |1, (Symbol) :left or :right| - included
  # @return (nil) if either string or another_string is invalid.
  #
  # @see valid?
  # @see include?
  def self.compare(string, another_string)
    if self.valid?(string) && self.valid?(another_string)
      # Determine mode of comparision
      str_p = self.valid?(string, :Permission)
      str_g = !str_p
      astr_p = self.valid?(another_string, :Permission)
      astr_g = !astr_p
      case
      when str_p && astr_p
        return 0 if string == another_string
        -1
      when str_p && astr_g
        bool = self.include?(string, another_string)
        bool ? 1 : -1
      when str_g && astr_p
        bool = self.include?(another_string, string)
        bool ? 1 : -1
      when str_g && astr_g
        return 0 if string == another_string
        sgroup_nodes = string.split(?.).each
        agroup_nodes = another_string.split(?.).each
        while true
          begin
            snode = sgroup_nodes.next
            anode = agroup_nodes.next
            return -1 if snode != anode
            return 1, :left if sgroup_nodes.peek == '*'
            return 1, :right if agroup_nodes.peek == '*'
          rescue StopIteration
            return -1
          end
        end
      end
    else
      nil
    end
  end
end
