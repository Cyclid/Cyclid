require 'spec_helper'

describe Cyclid::API::Health::Helpers do
  let :subject do
    Class.new{ extend Cyclid::API::Health::Helpers }
  end

  describe '#health_status' do
    it 'returns a SinatraHealthCheck response' do
      status = nil
      expect(status = subject.health_status(:ok, 'test')).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:ok)
      expect(status.message).to eq('test')
    end
  end
end
