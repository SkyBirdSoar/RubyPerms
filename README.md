RubyPerms
=========

An implementation (sort of) of Bukkit's SuperPerms in Ruby.

You should include PermissionSet in a player/user/etc class to use and call super(name, permissions)
The name in the source is referred to as nick because it was first intended for use in an IRC bot.
See the develop branch to see what I'm changing.

See a python implementation of the project done by @daboross: [PyPermissions](https://github.com/daboross/PyPermissions)

**Many thanks to:**
- @daboross
- Andrio

### Suggested ideas
- Create a `ClusterTracker` and have `PermissionCluster` report to it when it is instantiated.
  Then, have `Permission` check from `ClusterTracker` to see if PermissionCluster was defined with the same permission.
   - __Why?__ You should try to permission conflicts. `Permissible#clean` will remove the (n != 1<sup>st</sup>)<sup>th</sup> 
     it sees.