RubyPerms
=========

An implementation (sort of) of Bukkit's SuperPerms in Ruby.

You should include PermissionSet in a player/user/etc class to use and call super(name, permissions)
The name in the source is referred to as nick because it was first intended for use in an IRC bot.

TODO:
- Better way of caching.
    - Invalidate the whole cache on modify instead of checking the time each time
