require './plugins/ExtensionManager/Permissions/Permission'
require './plugins/ExtensionManager/Permissions/PermissionGroup'
require './plugins/ExtensionManager/Permissions/PermissionUtils'
require './plugins/ExtensionManager/Exceptions/InvalidComparisonError'

require 'observer'

# Intended to be included in Cinch::User but I don't know how
module PermissionSet
  include Enumerable
  include Comparable
  include Observable

  # @!attribute [r] permissions
  #   A list of permissions <user> has
  # @!attribute [r] last_modified
  #   The time permissions was last modified
  # @!attribute [r] last_
  #   Corresponding to cache_
  # @!attribute [r] cache_
  #   Caches method returns like sort, clean etc to not waste system resources
  attr_reader :permissions, :last_modified, :last_, :cache_, :nick

  # @param permissions [Array<Permission, PermissionGroup>]
  # @note permissions will be sorted immediately.
  # @note Unknown classes including Strings will be removed. Use #add_permission(Array<String>) instead.
  def initialize(nick, permissions)
    @nick = nick
    @permissions = permissions.select { |x| x.class == Permission || x.class == PermissionGroup }
    @last_modified = Time.now
    @last_ = {}
    @cache_ = {}
    sort!
  end

  # @return [Array<Permission, PermissionGroup>] Inversed self.
  # @note Calls #inverse internally
  # @see #inverse
  def !
    # Let inverse do all the work :P
    inverse
  end

  # Comparison
  # @param object [PermissionSet, Array]
  # @return [Integer] @permissions <=> object.permissions
  # @return [Integer] @permissions <=> object
  def <=>(object)
    case object
    when PermissionSet
      @permissions <=> object.permissions
    when Array
      @permissions <=> object
    else
      raise InvalidComparisonError
    end
  end

  # Get the Permission(Group) object at <index>
  # @param index [Integer]
  # @return [Permission, PermissionGroup] at <index>
  def [](index)
    @permissions[index]
  end

  # Add permissions into self
  # Supports:
  # - String
  # - Array<String, Permission, PermissionGroup>
  # - PermissionSet
  # @note Please use clean! after this if necessary.
  # @note Please use sort! after this if necessary.
  # @note This method modifies self
  # @note This method notifies observers.
  #
  # @param object [String, Array<String, Permission, PermissionGroup>, Permission, PermissionGroup, PermissionSet]
  # @return [nil] if not addable
  # @return [Array] that includes all objects that FAILED to be added
  # @return [Boolean] for single objects depending on success (Includes PermissionSet)
  def add_permission(object)
    case object
    when Array
      objects = object.select { |x| x.class == String }
      objectp = object.select { |x| x.class == Permission || x.class == PermissionGroup }
      @permissions = @permissions + objectp
      failedu = (object - objects) - objectp
      failed = []
      objects.each do |str|
        case
        when Permission.valid?(str)
          @permissions << Permission.new(str)
        when PermissionGroup.valid?(str)
          @permissions << PermissionGroup.new(str)
        else
          failed << str
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :add_permission_bulk,
        changed: ((objects.length - failed.length - failedu.length) + objectp.length),
        objects_concerned: {
          ipermission: objectp,
          string: {
            total: objects,
            failed: failed
            },
            unknown: failedu
            },
            total: @permissions.length
            })
      failed + failedu
    when String
      case
      when Permission.valid?(object)
        @permissions << Permission.new(object)
        update(
        {
          event: :on_modify,
          sub_event: :add_permission,
          changed: 1,
          objects_concerned: {
            ipermission: [],
            string: {
              total: [object],
              failed: []
              },
              unknown: 0
              },
              total: @permissions.length
              })
        true
      when PermissionGroup.valid?(object)
        @permissions << PermissionGroup.new(object)
        update(
        {
          event: :on_modify,
          sub_event: :add_permission,
          changed: 1,
          objects_concerned: {
            ipermission: [],
            string: {
              total: [object],
              failed: []
              },
              unknown: 0
              },
              total: @permissions.length
              })
        true
      else
        false
      end
    when Permission || PermissionGroup
      @permissions << object
      update(
      {
        event: :on_modify,
        sub_event: :add_permission,
        changed: 1,
        objects_concerned: {
          ipermission: [object],
          string: {
            total: [],
            failed: []
            },
            unknown: 0
            },
            total: @permissions.length
            })
      true
    when PermissionSet
      @permissions = @permissions + object.permissions
      update(
      {
        event: :on_modify,
        sub_event: :add_permission_bulk,
        changed: object.permissions.length,
        objects_concerned: {
          ipermission: [object.permissions],
          string: {
            total: [],
            failed: []
            },
            unknown: 0
            },
            total: @permissions.length
            })
      true
    else
      nil
    end
  end

  # Remove permissions from self
  # Supports:
  # - String
  # - Array<String, Permission, PermissionGroup>
  #
  # @note This method modifies self
  # @note This method notifies observers.
  #
  # @param object [String, Array<String, Permission, PermissionGroup>, Permission, PermissionGroup]
  # @return [nil] if not addable
  # @return [Array] for all objects that FAILED to be removed
  # @return [Boolean] for single objects depending on success
  def remove_permission(object)
    case object
    when Array
      objects = object.select { |x| x.class == String }
      objectp = object.select { |x| x.class == Permission || x.class == PermissionGroup }
      succp = @permissions & objectp
      @permissions = @permission - objectp
      failedp = objectp - succp
      failedu = (object - objects) - objectp
      failed = []
      objects.each do |str|
        case
        when PermissionUtils.valid?(str)
          deleted = @permission.delete_if { |x| x.permission == str }
          failed << str if delete.empty?
        else
          failed << str
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :remove_permission_bulk,
        changed: objects.length - (failedp.length + failedu.length + failed.length),
        objects_concerned: {
          ipermission: {
            total: object_p,
            failed: failedp
            },
            string: {
              total: objects,
              failed: failed
              },
              unknown: failedu
              },
              total: @permissions.length
              })
      failed + failedp + failedu
    when String
      deleted = @permissions.delete_if { |x| x.permission == object }
      update(
      {
        event: :on_modify,
        sub_event: :remove_permission,
        changed: deleted.empty? ? 0 : 1,
        objects_concerned: {
          ipermission: {
            total: [],
            failed: []
            },
            string: {
              total: [object],
              failed: deleted.empty? ? [object] : [] 
              },
              unknown: []
              },
              total: @permissions.length
              })
      !deleted.empty?
    when Permission && PermissionGroup
      deleted = @permissions.delete_if { |x| x.permission == object.permission }
      update(
      {
        event: :on_modify,
        sub_event: :remove_permission,
        changed: deleted.empty? ? 0 : 1,
        objects_concerned: {
          ipermission: {
            total: [object],
            failed: deleted.empty? ? [object] : []
            },
            string: {
              total: [],
              failed: [] 
              },
              unknown: []
              },
              total: @permissions.length
              })
      !deleted.empty?
    when PermissionSet
      raise NotImplementedError, "Removing permissions via PermissionSet is not recommended as you might remove basic permissions. If you still want to do this, turn PermissionSet into an array first."
    else
      nil
    end
  end

  # Removes the permissions for which block evaluates to true.
  # @note This method modifies self
  # @note This method notifies observers
  # @yield [Permission, PermissionGroup]
  # @return [self]
  def remove_permission_if(&block)
    removed = []
    if block_given?
      @permissions.reverse_each do |permission|
        boolean = block.call(permission)
        if boolean
          @permissions.delete(permission)
          removed << permission
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :remove_permission_if,
        changed: removed.length,
        objects_concerned: {
          ipermission: removed,
          string: nil,
          unknown: nil
          },
          total: @permissions.length
          })
      self
    else
      @permissions.to_enum
    end
  end

  # Check if PermissionSet has a permission
  # By logic you should only check for Permission and
  # not PermissionGroup strings.
  # Yet strangely, this method supports it
  #
  # @param permission [String, Permission, PermissionGroup]
  # @return [Boolean]
  def has_permission?(permission)
    case permission
    when String
      case
      when Permission.valid?(permission)
        @permissions.any? do |x|
          if x.class == PermissionGroup
            return true if x.include? permission
          else
            return true if x == permission
          end
        end
        false
      when PermissionGroup.valid?(permission)
        @permissions.any? do |x|
          if x.class == PermissionGroup
            num, _ = PermissionUtils.compare(x.permission, permission)
            return true if num == 0 || num == 1
          end
        end
        false
      else
        nil
      end
    when Permission
      @permissions.any? do |x|
        if x.class == PermissionGroup
          return true if x.include? permission
        else
          return true if x == permission
        end
      end
      false
    when PermissionGroup
      @permissions.any? do |x|
        if x.class == PermissionGroup
          num, _ = PermissionUtils.compare(x.permission, permission)
          return true if num == 0 || num == 1
        end
      end
      false
    else
      nil
    end
  end

  alias_method :include?, :has_permission?

  # Iterate through @permissions
  # @yield permission
  def each(&block)
    if block_given?
      @permissions.each do |permission|
        block.call permission
      end
    else
      @permissions.to_enum
    end
  end

  # Check if @permissions is empty
  # @return [Boolean]
  def empty?
    @permissions.empty?
  end

  alias_method :cleared?, :empty?

  # Empties self.
  # @note Dangerous method. Use with care.
  # @note This method modifies self
  # @note This method notifies observers.
  # @return [nil]
  def empty!
    old = Array.new(@permissions)
    @permissions.clear
    update(
    {
      event: :on_modify,
      sub_event: :empty,
      changed: old.length,
      objects_concerned: {
        ipermission: nil,
        string: nil,
        unknown: nil
        },
        total: 0
        })
  end

  alias_method :clear!, :empty!

  # Change @last_modified to now
  # @note This method notifies observers
  # @note This method is meant for testing only.
  # @return [Time] @last_modified
  def touch!
    update(
    {
      event: :touch,
      sub_event: nil,
      changed: 0,
      objects_concerned: {
        ipermission: nil,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
  end

  # Remove duplicates
  # @return [Array<Permission, PermissionGroup>] The cleaned self
  def clean
    if @cache_.key?(:cleaned)
      if @last_[:cleaned] > @last_modified
        @cache_[:cleaned]
      else
        clean = clean_priv
        @last_[:cleaned] = Time.now
        @cache_[:cleaned] = clean
        clean
      end
    else
      clean = clean_priv
      @last_[:cleaned] = Time.now
      @cache_[:cleaned] = clean
      clean
    end
  end

  alias_method :uniq, :clean

  # Remove duplicates from self
  # @note This method modifies self.
  # @note This method notifies observers.
  # @return [self]
  def clean!
    old = Array.new(@permissions)
    @permissions = clean
    update(
    {
      event: :on_modify,
      sub_event: :clean,
      changed: (old - @permissions).length,
      objects_concerned: {
        ipermission: nil,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  alias_method :uniq!, :clean!

  # Sorts @permissions according to these rules:
  # - Negated first
  # - Groups last
  # @return [Array<Permission, PermissionGroup>]
  def sort
    if @cache_.key?(:sorted)
      if @last_[:sorted] > @last_modified
        @cache_[:sorted]
      else
        sort = sorting
        @last_[:sorted] = Time.now
        @cache_[:sorted] = sort
        sort
      end
    else
      sort = sorting
      @last_[:sorted] = Time.now
      @cache_[:sorted] = sort
      sort
    end
  end

  # Sorts @permissions according to these rules:
  # - Negated first
  # - Groups last
  # @note This method modifies self
  # @note This method notifies observers
  # @return [self]
  def sort!
    @permissions = sort
    update(
    {
      event: :on_modify,
      sub_event: :sort,
      changed: @permissions.length,
      objects_concerned: {
        ipermission: @permissions,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  def inspect
    "#<PermissionSet:0x#{'%x' % (self.object_id << 1)} Owner=#{@nick} Permission_Count=#{@permissions.length}>"
  end

  def to_str
    "#<PermissionSet:0x#{'%x' % (self.object_id << 1)} Owner=#{@nick} Permission_Count=#{@permissions.length}"
  end

  def to_s
    "#<PermissionSet:0x#{'%x' % (self.object_id << 1)} Owner=#{@nick} Permission_Count=#{@permissions.length}"
  end

  def min
    nil
  end

  def max
    nil
  end

  def last
    @permissions[-1]
  end

  # Inverses all permissions.
  # (same as !permission)
  # @return [Array<Permission, PermissionGroup>]
  def inverse
    if @cache_.key?(:inversed)
      if @last_[:inversed] > @last_modified
        @cache_[:inversed]
      else
        inverse = inverse_all
        @last_[:inversed] = Time.now
        @cache_[:inversed] = inverse
        inverse
      end
    else
      inverse = inverse_all
      @last_[:inversed] = Time.now
      @cache_[:inversed] = inverse
      inverse
    end
  end

  # Inverses all permissions.
  # (same as !permission)
  # @note This method modifies self
  # @note This method notifies observers
  # @return [self]
  def inverse!
    @permissions = inverse
    update(
    {
      event: :on_modify,
      sub_event: :inverse,
      changed: @permissions.length,
      objects_concerned: {
        ipermission: @permissions,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  # Inverse all permissions for which block evaluates to true.
  # @note This method modifies self
  # @note This method notifies observers
  # @yield [Permission, PermissionGroup]
  # @return [self]
  def inverse_if(&block)
    inversed = []
    if block_given?
      @permissions.each do |permission|
        boolean = block.call(permission)
        if boolean
          permission.inverse!
          inversed << permission
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :inverse_if,
        changed: inversed.length,
        objects_concerned: {
          ipermission: inversed,
          string: nil,
          unknown: nil
          },
          total: @permissions.length
          })
      self
    else
      @permissions.to_enum
    end
  end

  # Forces negation on permissions for which block evaluates to true.
  # @note This method modifies self
  # @note This method notifies observers
  # @yield [Permission, PermissionGroup]
  # @return [self]
  def force_negation_if(&block)
    negated = []
    if block_given?
      @permissions.each do |permission|
        boolean = block.call(permission)
        if boolean
          permission.negate!
          negated << permission
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :force_negation_if,
        changed: negated.length,
        objects_concerned: {
          ipermission: negated,
          string: nil,
          unknown: nil
          },
          total: @permissions.length
          })
      self
    else
      @permissions.to_enum
    end
  end

  # Forces un-negation on permissions for which block evaluates to true.
  # @note This method modifies self
  # @note This method notifies observers
  # @yield [Permission, PermissionGroup]
  # @return [self]
  def force_un_negation_if(&block)
    unnegated = []
    if block_given?
      @permissions.each do |permission|
        boolean = block.call(permission)
        if boolean
          permission.negate!(false)
          unnegated << permission
        end
      end
      update(
      {
        event: :on_modify,
        sub_event: :force_un_negation_if,
        changed: unnegated.length,
        objects_concerned: {
          ipermission: unnegated,
          string: nil,
          unknown: nil
          },
          total: @permissions.length
          })
      self
    else
      @permissions.to_enum
    end
  end

  # All Permissions will be negated
  # @return [Array<Permission, PermissionGroup>]
  def negate
    if @cache_.key?(:negated)
      if @last_[:negated] > @last_modified
        @cache_[:negated]
      else
        negated = []
        @permissions.each do |permission|
          negated << permission.negate
        end
        @last_[:negated] = Time.now
        @cache_[:negated] = negated
        negated
      end
    else
      negated = []
      @permissions.each do |permission|
        negated << permission.negate
      end
      @last_[:negated] = Time.now
      @cache_[:negated] = negated
      negated
    end
  end

  # All Permissions will be negated
  # @note This method modifies self
  # @note This method notifies observers
  # @return [self]
  def negate!
    @permissions = negate
    update(
    {
      event: :on_modify,
      sub_event: :negate,
      changed: @permissions.length,
      objects_concerned: {
        ipermission: @permissions,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  # All Permissions will be un-negated
  # @return [Array<Permission, PermissionGroup>]
  def un_negate
    if @cache_.key?(:unnegated)
      if @last_[:unnegated] > @last_modified
        @cache_[:unnegated]
      else
        unnegated = []
        @permissions.each do |permission|
          unnegated << permission.negate(false)
        end
        @last_[:unnegated] = Time.now
        @cache_[:unnegated] = unnegated
        unnegated
      end
    else
      unnegated = []
      @permissions.each do |permission|
        unnegated << permission.negate(false)
      end
      @last_[:unnegated] = Time.now
      @cache_[:unnegated] = unnegated
      unnegated
    end
  end

  # All Permissions will be un-negated
  # @note This method modifies self
  # @note This method notifies observers
  # @return [self]
  def un_negate!
    @permissions = un_negate
    update(
    {
      event: :on_modify,
      sub_event: :unnegate,
      changed: @permissions.length,
      objects_concerned: {
        ipermission: @permissions,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  # Get an array of negated permissions
  # @note This method is preferred instead of self.permissions.select
  #   as it caches the result
  # @return [Array<Permission, PermissionGroup>]
  def negated
    if @cache_.key?(:negated_list)
      if @last_[:negated_list] > @last_modified
        @cache_[:negated_list]
      else
        negated_list = @permissions.select do |permission|
          permission.negated?
        end
        @last_[:negated_list] = Time.now
        @cache_[:negated_list] = negated_list
        negated_list
      end
    else
      negated_list = @permissions.select do |permission|
        permission.negated?
      end
      @last_[:negated_list] = Time.now
      @cache_[:negated_list] = negated_list
      negated_list
    end
  end

  # Get an array of un-negated permissions
  # @note This method is preferred instead of self.permissions.select
  #   as it caches the result
  # @return [Array<Permission, PermissionGroup>]
  def un_negated
    if @cache_.key?(:unnegated_list)
      if @last_[:unnegated_list] > @last_modified
        @cache_[:unnegated_list]
      else
        unnegated_list = @permissions.select do |permission|
          !permission.negated?
        end
        @last_[:unnegated_list] = Time.now
        @cache_[:unnegated_list] = unnegated_list
        unnegated_list
      end
    else
      unnegated_list = @permissions.select do |permission|
        !permission.negated?
      end
      @last_[:unnegated_list] = Time.now
      @cache_[:unnegated_list] = unnegated_list
      unnegated_list
    end
  end

  # Turn everything into PermissionGroup
  # @return [Array<PermissionGroup>]
  def force_group
    if @cache_.key?(:force_group)
      if @last_[:force_group] > @last_modified
        @cache_[:force_group]
      else
        force_group = []
        @permissions.each do |permission|
          if permission.class == Permission
            force_group << permission.broaden
          else
            force_group << permission
          end
        end
        @last_[:force_group] = Time.now
        @cache_[:force_group] = force_group
        force_group
      end
    else
      force_group = []
      @permissions.each do |permission|
        if permission.class == Permission
          force_group << permission.broaden
        else
          force_group << permission
        end
      end
      @last_[:force_group] = Time.now
      @cache_[:force_group] = force_group
      force_group
    end
  end


  # Turn everything into PermissionGroup
  # @note This method modifies self
  # @note This method notifies observers
  # @return [self]
  def force_group!
    @permissions = force_group
    update(
    {
      event: :on_modify,
      sub_event: :force_group,
      changed: @permissions.length,
      objects_concerned: {
        ipermission: @permissions,
        string: nil,
        unknown: nil
        },
        total: @permissions.length
        })
    self
  end

  # Get an array of PermissionGroups in self
  # @note This method is preferred instead of self.permissions.select
  #   as it caches the result
  # @return [Array<Permission, PermissionGroup>]
  def get_groups
    if @cache_.key?(:get_groups)
      if @last_[:get_groups] > @last_modified
        @cache_[:get_groups]
      else
        get_groups = @permissions.select do |permission|
          permission.class == PermissionGroup
        end
        @last_[:get_groups] = Time.now
        @cache_[:get_groups] = get_groups
        get_groups
      end
    else
      get_groups = @permissions.select do |permission|
        permission.class == PermissionGroup
      end
      @last_[:get_groups] = Time.now
      @cache_[:get_groups] = get_groups
      get_groups
    end
  end

  # Get an array of Permissions in self
  # @note This method is preferred instead of self.permissions.select
  #   as it caches the result
  # @return [Array<Permission, PermissionGroup>]
  def get_non_groups
    if @cache_.key?(:get_non_groups)
      if @last_[:get_non_groups] > @last_modified
        @cache_[:get_non_groups]
      else
        get_non_groups = @permissions.select do |permission|
          permission.class == Permission
        end
        @last_[:get_non_groups] = Time.now
        @cache_[:get_non_groups] = get_non_groups
        get_non_groups
      end
    else
      get_non_groups = @permissions.select do |permission|
        permission.class == Permission
      end
      @last_[:get_non_groups] = Time.now
      @cache_[:get_non_groups] = get_non_groups
      get_non_groups
    end
  end

  # Forces group on Permission for which block evaluates to true.
  # @note This method modifies self
  # @note This method notifies observers
  # @yield [Permission]
  # @return [self]
  def force_group_if(&block)
    force_group_if = []
    if block_given?
      @permissions.each do |permission|
        if permission.class == Permission
          boolean = block.call(permission)
          if boolean
            force_group_if << permission.broaden
          else
            force_group_if << permission
          end
        else
          force_group_if << permission # Have to do this so won't have missing permissions
        end
      end
      @permissions = force_group_if
      update(
      {
        event: :on_modify,
        sub_event: :force_group_if,
        changed: @permissions.length,
        objects_concerned: {
          ipermission: @permissions,
          string: nil,
          unknown: nil
          },
          total: @permissions.length
          })
      self
    else
      @permissions.to_enum
    end
  end

  def reset_cache!
    @last_.clear
    @cache_.clear
  end

  private
  def update(*args)
    @last_modified = Time.now
    changed
    notify_observers(*args)
    @last_modified
  end

  def inverse_all
    inversed = []
    @permissions.each do |permission|
      inversed << permission.inverse
    end
    inversed
  end

  def sorting
    @permissions.sort do |a, b|
      ap = a.class == Permission
      ag = !ap
      bp = b.class == Permission
      bg = !bp
      an = a.negated?
      bn = b.negated?
      case
      when ap && bp
        case
        when an && bn
          a.permission <=> b.permission
        when an && !bn
          # Place negated first
          -1
        when !an && bn
          1
        when !an && !bn
          a.permission <=> b.permission
        end
      when ap && bg
        case
        when an && bn
          # Place Groups last
          -1
        when an && !bn
          # Place negated first
          1
        when !an && bn
          -1
        when !an && !bn
          # Place Groups last
          -1
        end
      when ag && bp
        case
        when an && bn
          # Place Groups last
          1
        when an && !bn
          # Place negated first
          -1
        when !an && bn
          1
        when !an && !bn
          # Place Groups last
          1
        end
      when ag && bg
        case
        when an && bn
          a.permission <=> b.permission
        when an && !bn
          # Place negated first
          -1
        when !an && bn
          1
        when !an && !bn
          a.permission <=> b.permission
        end
      end
    end
  end

  def clean_priv
    list = []
    cleaned = []
    @permissions.each do |x|
      unless list.include?(x.permission)
        list << x.permission
        cleaned << x
      end
    end
    super_clean(cleaned)
  end

  # Credits to Andrio for telling me I should reverse_each instead.
  def super_clean(cleaned)
    temp = cleaned.select { |x| x.class == Permission }
    tempg = cleaned.select { |x| x.class == PermissionGroup }
    tempg.each do |group|
      tempg.reverse_each do |group2|
        num, side = PermissionUtils.compare(group.permission, group2.permission)
        if num == 1
          case side
          when :left then tempg.delete(group2)
          when :right then tempg.delete(group)
          end
        end
      end
    end
    tempg.each do |group|
      temp.reverse_each do |perm|
        temp.delete(perm) if group.include? perm
      end
    end
    temp + tempg
  end
end
