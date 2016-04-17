require 'spec_helper'
require 'net/ssh/test'

describe Cyclid::API::Plugins::Ssh do
  include Net::SSH::Test

  before :each do
    @ssh = class_double('Net::SSH').as_stubbed_const
    allow(@ssh).to receive(:start).and_return(true)
  end

  it 'should create a new instance' do
    expect(@ssh).to receive(:start).with('localhost',
                                         'test',
                                         password: nil,
                                         keys: nil,
                                         timeout: 5).ordered
    expect do
      Cyclid::API::Plugins::Ssh.new(host: 'localhost',
                                    user: 'test',
                                    log: nil)
    end.to_not raise_error
  end

  it 'should execute a command' do
    transport = nil

    story do |session|
      channel = session.opens_channel
      channel.sends_exec '/bin/true'
      channel.gets_data 0
    end

    # XXX And, um, how in the hell do we create a usable Session from that script? The stub for
    # Net::SSH.start currently returns 'true'. Amazingly, there is no Net::SSH::Test::Session;
    # just a Channel, but _that's_ supposed to be returned by session.open_channel, and if we
    # create a mock class how does that connect to the story defined above?
    expect do
      transport = Cyclid::API::Plugins::Ssh.new(host: 'localhost',
                                                user: 'test',
                                                log: nil)
    end.to_not raise_error

    expect(transport.exec('/bin/true')).to be true
  end
end
