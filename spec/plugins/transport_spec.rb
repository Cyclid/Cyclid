require 'spec_helper'

describe Cyclid::API::Plugins::Transport do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Transport.human_name).to eq('transport')
  end

  context 'creating a new Transport plugin' do
    before :all do
      @transport = Cyclid::API::Plugins::Transport.new
    end

    it 'should export an environment' do
      expect{ @transport.export_env(a: 1, b: 2) }.to_not raise_error
    end

    it 'should close a connection if one was not opened' do
      expect(@transport.close).to be_nil
    end

    it 'should not execute a command' do
      expect(@transport.exec('/bin/true')).to be false
    end

    it 'should not upload a file' do
      expect(@transport.upload(nil, '/tmp/file')).to be false
    end

    it 'should not download a file' do
      expect(@transport.download(nil, '/tmp/file')).to be false
    end
  end
end
