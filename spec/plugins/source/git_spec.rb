require 'spec_helper'

describe Cyclid::API::Plugins::Git do
  it 'creates a new instance' do
    expect{ Cyclid::API::Plugins::Git.new }.to_not raise_error
  end

  class TestTransport
    attr_reader :cmd, :path

    def exec(cmd, path = nil)
      @cmd = cmd
      @path = path
      true
    end
  end

  it 'clones a git repository' do
    transport = TestTransport.new
    sources = { url: 'https://test.example.com/example/test' }

    git = nil
    expect{ git = Cyclid::API::Plugins::Git.new }.to_not raise_error
    expect(git.checkout(transport, nil, sources)).to be true
    expect(transport.cmd).to eq('git clone https://test.example.com/example/test')
  end

  it 'clones a git repository with an OAuth token' do
    transport = TestTransport.new
    sources = { url: 'https://test.example.com/example/test', token: 'abcxyz' }

    git = nil
    expect{ git = Cyclid::API::Plugins::Git.new }.to_not raise_error
    expect(git.checkout(transport, nil, sources)).to be true
    expect(transport.cmd).to eq('git clone https://abcxyz@test.example.com/example/test')
  end

  it 'clones a git repository with a branch' do
    transport = TestTransport.new
    sources = { url: 'https://test.example.com/example/test', branch: 'test' }
    ctx = { workspace: '/test' }

    git = nil
    expect{ git = Cyclid::API::Plugins::Git.new }.to_not raise_error
    expect(git.checkout(transport, ctx, sources)).to be true
    expect(transport.path).to eq('/test/test')
    expect(transport.cmd).to eq('git checkout test')
  end
end