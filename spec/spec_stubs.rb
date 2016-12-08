# frozen_string_literal: true
# Stub LogBuffer analogue
class TestLog
  attr_reader :data

  def write(data)
    @data = data
  end
end
