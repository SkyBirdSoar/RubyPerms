require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionGroup')

# Used for handling Permission and PermissionGroup
# strings for operations such as comparing and such.
class PermissionUtils
  # Check if a string is negated.
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
  def self.negated?(string)
    return true if string.start_with?(?-)
    false
  end

  # Opposite of {::negated?}.
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
  def self.allowed?(string)
    !self.negated?(string)
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

  # Creates a new Permission(Group) object based on a string
  # @param string [String] The Permission(Group) string
  # @return [Permission, PermissionGroup]
  def self.create(string)
    if string.end_with?('.*')
      PermissionGroup.new(string)
    else
      Permission.new(string)
    end
  end
end
