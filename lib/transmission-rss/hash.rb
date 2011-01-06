class Hash
  # If a method is missing it is interpreted as the key of the hash. If the
  # method has an argument (for example by "method="), the key called "method"
  # is set to the respective argument.
  def method_missing(symbol, *args)
    if(args.size == 0)
      self[symbol.to_s]
    else
      self[symbol.to_s.slice(0..-2)] = args.first
    end
  end
end
