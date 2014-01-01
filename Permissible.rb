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

  # @param starting_permissions [Permissible, Array<String, Permissible, Permission, PermissionGroup>, String, Permission, PermissionGroup]
  def initialize(starting_permissions)
    @permissions = []
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
    when Permission || PermissionGroup
      @permissions << permissions
      update(:add, {objects: [permissions]})
    when Permissible
      clear! if clear
      
    when Array
    end
  end

  def clear!
    update(:remove, {objects: @permissions})
    @permissions.clear
    true
  end
  alias_method :empty!, :clear!
