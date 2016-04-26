class Object
  def linux?
    RUBY_PLATFORM.downcase.include?('linux')
  end
end
