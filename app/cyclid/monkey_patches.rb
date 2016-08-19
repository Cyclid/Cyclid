# frozen_string_literal: true
# Add two methods to Hash
class Hash
  # http://chrisholtz.com/blog/lets-make-a-ruby-hash-map-method-that-returns-a-hash-instead-of-an-array/
  def hmap
    inject({}) do |hash, (k, v)|
      hash.merge(yield(k, v))
    end
  end

  # Interpolate the data in the ctx hash into any String values
  def interpolate(ctx)
    hmap do |key, value|
      if value.is_a? String
        { key => value % ctx }
      else
        { key => value }
      end
    end
  end
end

# Add a method to Array
class Array
  # Interpolate the data in the ctx hash for each String & Hash item
  def interpolate(ctx)
    map do |entry|
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
