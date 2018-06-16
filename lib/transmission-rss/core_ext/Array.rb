class Array
  def duplicates
    self.group_by { |e| e }.select { |k, v| v.size > 1 }.map(&:first)
  end
end
