class WildHelper
  def self.include?(wild, permission)
    permission.start_with?(wild.permission.chomp(?*))
  end
end
