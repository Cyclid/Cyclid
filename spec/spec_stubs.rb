# Stub LogBuffer analogue
class TestLog
  attr_reader :data

  def write(data)
    puts "data=#{data}"
    @data = data
  end
end
