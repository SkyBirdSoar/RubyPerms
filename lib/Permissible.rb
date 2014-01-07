require File.join(File.expand_path(File.dirname(__FILE__)), 'WildPermission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'Permission')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionCluster')
require File.join(File.expand_path(File.dirname(__FILE__)), 'PermissionResolver')
module Permissible
  include PermissionResolver
end
