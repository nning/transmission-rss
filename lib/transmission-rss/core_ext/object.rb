class Object
  def bsd?
    RUBY_PLATFORM.include?('bsd')
  end

  def linux?
    RUBY_PLATFORM.downcase.include?('linux')
  end
end
