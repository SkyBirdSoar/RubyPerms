require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionGroup')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionUtils')

module Permissible
  include Enumerable

  # @!attribute [r] permissions
  #   The array of permissions this Permissible has
  # @!attribute [r] cache
  #   stores permissions from permissions-changing events
  attr_reader :permissions, :cache

  # @param starting_permissions [Permissible, Array<String, Permissible, Permission, PermissionGroup, PermissionCluster>, String, Permission, PermissionGroup, PermissionCluster]
  def initialize(starting_permissions)
    @permissions = []
    @cache = {}
    add_permission(starting_permissions)
    sort!
  end

  def add_permission(permissions, clear = false)
    case permissions
    when String
      begin
        p = PermissionUtils.create(permissions)
        @permissions << p
        update(:add, {objects: [p]})
        true
      rescue RuntimeError
        false
      end
    when Permission || PermissionGroup || PermissionCluster
      @permissions << permissions
      update(:add, {objects: [permissions]})
    when Permissible
      clear! if clear
      @permissions << permissions.permissions
      update(:add, {objects: permissions.permissions})
    when Array
      clear! if clear
      permissions.each { |x| add_permission(x) }
    end
  end

  def clear!
    update(:remove, {objects: @permissions})
    @permissions.clear
    true
  end
  alias_method :empty!, :clear!

  def empty?
    @permissions.empty?
  end

  def remove_permission(permissions)
    case permissions
    when String
      @permissions.delete_if { |x| x == permissions }
      update(:remove, {objects: permissions})
    when Permission || PermissionGroup || PermissionCluster
      remove_permission(permissions.permission)
    when Permissible || Array
      permissions.each { |x| remove_permission(x) }
    end
  end

  def has_permission?(permission)
    case permission
    when String
      @permissions.each do |x|
        case x.class
        when Permission
          if x == permission
            return x.negated ? false : true
          end
        when PermissionGroup
          if x == permission || x.include?(permission)
            return x.negated ? false : true
          end
        when PermissionCluster
          if x == permission || x.has_child?(permission)
            return x.negated ? false : true
          end
        end
      end
      false
    when Permission || PermissionGroup || PermissionCluster
      has_permission?(permission.permission)
    else
      nil
    end
  end

  def sort(instance = true)
    temp = @cache.key?(:sort) ? @cache[:sort] : @cache[:sort] = psort
    instance ? self.class.new(temp) : temp
  end

  def sort!
    @permissions = sort(false)
    @cache.clear
    update(:bang!, {event: :sort})
  end

  def inverse
    temp = @cache.key?(:inverse) ? @cache[:inverse] : @cache[:inverse] = pinverse
    instance ? self.class.new(temp) : temp
  end
  alias_method :'!', :inverse

  def inverse!
    @permissions = inverse(false)
    @cache.clear
    update(:bang!, {event: :inverse})
  end

  def inverse_if(&block)
    if block_given?
      @permissions.each do |permission|
        permission.inverse! if block.call(permission)
      end
      @cache.clear
      update(:if, {event: :inverse})
    end
  end

  def negate(negate = true, instance = true)
    temp = @cache.key?(:negate) ? @cache[:negate] : @cache[:negate] = pnegate(negate)
    instance ? self.class.new(temp) : temp
  end

  def negate!(negate_ = true)
    @permissions = negate(negate_, false)
    @cache.clear
    update(:bang!, {event: :negate})
  end

  def negate_if(negate = true, &block)
    if block_given?
      @permissions.each do |permission|
        permission.negate!(negate) if block.call(permission)
      end
      @cache.clear
      update(:if, {event: :negate})
    end
  end

  def reset_cache!
    @cache.clear
  end

  def clean(log = false, instance = true)
    temp = @cache.key?(:clean) ? @cache[:iclean] : @cache[:clean] = pclean(log)
    instance ? self.class.new(temp) : temp
  end

  def clean!(log = false)
    @permissions = clean(log, false)
    @cache.clear
    update(:bang!, {event: :clean})
  end

  private
  def psort
    @permissions.sort do |a, b|
      if a.negated == b.negated
        a.permission <=> b.permission
      elsif a.negated && !b.negated
        -1
      elsif !a.negated && b.negated
        1
      end
    end
  end

  def pinverse
    @permissions.map { |x| !x }
  end

  def pnegate(negate)
    @permissions.each { |x| x.negate!(negate) }
  end

  def pclean(log)
    if log
      puts "Starting Clean Lv. 1"
      puts "--------------------"
      cleanup = []
      defined_str = []
      @permissions.each do |x|
        print "Checking #{x.inspect}... "
        unless defined_str.include?(x.permission)
          cleanup << x
          defined_str << x.permission
          puts "Safe!"
          next
        end
        puts "Duplicate."
      end
      puts "Clean Lv. 1 complete. Found #{@permission.length - cleanup.length} duplicates."
      pclean2(log, cleanup)
    else
      cleanup = []
      defined_str = []
      @permissions.each do |x|
        unless defined_str.include?(x.permission)
          cleanup << x
          defined_str << x.permission
        end
      end
      pclean2(log, cleanup)
    end
  end

  def pclean2(log, cleanup)
    if log
      puts "Starting Clean Lv. 2"
      puts "--------------------"

      puts "Organising permissions based on classes..."
      permissions, groups, clusters = [], [], []
      cleanup.each do |x|
        case x
        when Permission then permissions << x
        when PermissionGroup then groups << x
        when PermissionCluster then clusters << x
        else
          puts "Failed to identify #{x.inspect}!"
        end
      end
      puts "Done!"
      puts "Checking clusters for duplicates..."
      alr_defined = []
      clusters.each do |x|
        x.reverse_each do |y|
          if alr_defined.include?(y.permission)
            x.remove_child(y)
            puts "Removing #{y.inspect} from #{x.inspect}"
          else
            alr_defined << y.permission
          end
        end
      end
      puts "Clean Lv. 2 complete."
      pclean3(log, permissions, groups, clusters)
    else
      permissions, groups, clusters = [], [], []
      cleanup.each do |x|
        case x
        when Permission then permissions << x
        when PermissionGroup then groups << x
        when PermissionCluster then clusters << x
        end
      end
      alr_defined = []
      clusters.each do |x|
        x.reverse_each do |y|
          if alr_defined.include?(y.permission)
            x.remove_child(y)
          else
            alr_defined << y.permission
          end
        end
      end
      pclean3(log, permissions, groups, clusters)
    end
  end

  def pclean3(log, permissions, groups, clusters)
    if log
      puts "Starting Clean Lv. 3"
      puts "--------------------"
      puts "Removing Permission(Group) objects that are already defined in PermissionClusters."
      clusters.each do |x|
        permissions.reverse_each do |y|
          if x.has_child?(y) && x.negated == y.negated
            permissions.delete(y)
            puts "Removed #{y.inspect}."
          end
        end
        groups.reverse_each do |y|
          if x.has_child?(y) && x.negated == y.negated
            groups.delete(y)
            puts "Removed #{y.inspect}."
          end
        end
      end

      puts "Done."
      puts "Removing redundant permissions that are already included in groups."

      groups.each do |x|
        permissions.reverse_each do |y|
          if x.include?(y) # include? checks for negated too! <3
            permissions.delete(y)
            puts "Removed #{y.inspect}."
          end
        end
        clusters.each do |y|
          y.reverse_each do |z|
            if x.include?(z)
              y.remove_child(z)
              puts "Removed #{z.inspect} from #{y.inspect}"
            end
          end
        end
      end
      puts "Clean Lv. 3, there are %d Permissions, %d PermissionGroups and %d PermissionClusters left." % [permissions.length, groups.length, clusters.length]
      [permissions, groups, clusters].flatten
    else
      clusters.each do |x|
        permissions.reverse_each do |y|
          permissions.delete(y) if x.has_child?(y) && x.negated == y.negated
        end
        groups.reverse_each do |y|
          groups.delete(y) if x.has_child?(y) && x.negated == y.negated
        end
      end

      groups.each do |x|
        permissions.reverse_each do |y|
          permissions.delete(y) if x.include?(y) # include? checks for negated too! <3
        end
        clusters.each do |y|
          y.reverse_each do |z|
            y.remove_child(z) if x.include?(z)
          end
        end
      end
      [permissions, groups, clusters].flatten
    end
  end
end

