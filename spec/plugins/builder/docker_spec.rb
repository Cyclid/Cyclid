# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Docker do
  subject do
    Cyclid::API::Plugins::Docker.new
  end

  let :container do
    instance_double(::Docker::Container)
  end

  let :host do
    '123456789'
  end

  it 'should create a new instance' do
    expect{ subject }.to_not raise_error
  end

  context 'obtaining a build host' do
    before :each do
      i = class_double(::Docker::Image).as_stubbed_const
      expect(i).to receive(:create)

      c = class_double(::Docker::Container).as_stubbed_const
      expect(c).to receive(:create).and_return(container)
    end

    context 'with default arguments' do
      it 'returns a host with appropriate defaults' do
        expect(container).to receive(:start)
        expect(container).to receive(:id).and_return(42)

        buildhost = subject.get
        expect(buildhost.transports).to match_array(['dockerapi'])
        expect(buildhost[:username]).to match('root')
        expect(buildhost[:workspace]).to match('/root')
        expect(buildhost[:distro]).to match('ubuntu')
        expect(buildhost[:release]).to match('trusty')
      end
    end

    context 'with non-default arguments' do
      it 'returns a host with the desired distribution & release' do
        expect(container).to receive(:start)
        expect(container).to receive(:id).and_return(42)

        buildhost = subject.get(os: 'debian_7')
        expect(buildhost.transports).to match_array(['dockerapi'])
        expect(buildhost[:username]).to match('root')
        expect(buildhost[:workspace]).to match('/root')
        expect(buildhost[:distro]).to match('debian')
        expect(buildhost[:release]).to match('7')
      end
    end
  end

  context 'releasing a build host' do
    before :each do
      c = class_double(::Docker::Container).as_stubbed_const
      expect(c).to receive(:get).with(host).and_return(container)
    end

    it 'releases a build host' do
      buildhost = double(Cyclid::API::Plugins::DockerHost)
      expect(buildhost).to receive(:[]).with(:host).and_return(host)
      expect(container).to receive(:delete)

      expect{ subject.release(nil, buildhost) }.to_not raise_error
    end
  end

  describe '#create_name' do
    it 'returns a unique name with the configured name prefix' do
      instance_name = nil
      expect{ instance_name = subject.send(:create_name) }.to_not raise_error
      expect(instance_name).to match(/cyclid-build-\S{16}/)
    end
  end
end
