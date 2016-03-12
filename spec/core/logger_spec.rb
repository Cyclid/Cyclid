require 'spec_helper'

describe Logger do
  before :each do
    @logger = Cyclid.logger
  end

  it 'should be a Logger instance' do
      expect(@logger).to be_an_instance_of Logger
  end
end
