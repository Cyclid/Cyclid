class Hash
  # http://chrisholtz.com/blog/lets-make-a-ruby-hash-map-method-that-returns-a-hash-instead-of-an-array/
  def hmap(&block)
    self.inject({}) do |hash, (k,v)|
      hash.merge(block.call(k, v))
    end
  end

  def interpolate(ctx)
    self.hmap do |key, value|
      if value.is_a? String
        {key => value % ctx}
      else
        {key => value}
      end
    end
  end
end

class Array
  def interpolate(ctx)
    self.map do |entry|
      if entry.is_a? Hash
        entry.interpolate ctx
      elsif entry.is_a? String
        entry % @ctx
      else
        entry
      end
    end
  end
end
