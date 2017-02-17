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
  def %(other)
    hmap do |key, value|
      if value.is_a? String
        { key => value ** other }
      else
        { key => value }
      end
    end
  end
end

# Add a method to Array
class Array
  # Interpolate the data in the ctx hash for each String & Hash item
  def %(other)
    map do |entry|
      if entry.is_a? Hash
        entry % other
      elsif entry.is_a? String
        entry ** other
      else
        entry
      end
    end
  end
end

# Add a method to String
class String
  # Provide a "safe" version of the % (interpolation) operator; if a key does
  # not exist in arg, catch the KeyError and insert it as a nil value, and
  # continue.
  #
  # We're using the ** operator as it's one that isn't already used by String,
  # and it's abusing % already so hey, why not. FTP
  def **(other)
    res = nil
    arg = other ? other.dup : {}

    begin
      res = self % arg
    rescue KeyError => ex
      # Extract the key name from the exception message (sigh)
      match = ex.message.match(/\Akey{(.*)} not found\Z/)
      key = match[1]

      # Inject key with a default value and try again
      arg[key.to_sym] = nil
    end while res.nil? # rubocop:disable Lint/Loop

    return res
  end
end
