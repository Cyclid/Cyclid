# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Google do
  subject do
    Cyclid::API::Plugins::Google.new
  end

  before :each do
    Fog.mock!
    Fog::Mock.reset
  end

  it 'should create a new instance' do
    expect{ subject }.to_not raise_error
  end

  context 'obtaining a build host' do
    let :server_double do
      dbl = instance_double(Fog::Compute::Google::Server)
      allow(dbl).to receive(:public_ip_address).and_return('192.168.1.99')

      dbl
    end

    context 'with default arguments' do
      it 'returns a host with appropriate defaults' do
        expect(subject).to receive(:find_source_image)
          .with('ubuntu', 'trusty')
          .and_return(['ubuntu-trusty-test', 9999])
        expect(subject).to receive(:create_disk)
          .with(/.*/, 9999, 'ubuntu-trusty-test')
          .and_return('test-disk')
        expect(subject).to receive(:create_instance)
          .with(/.*/, 'test-disk')
          .and_return(server_double)

        buildhost = subject.get
        expect(buildhost.transports).to match_array(['ssh'])
        expect(buildhost[:username]).to match('build')
        expect(buildhost[:workspace]).to match('/home/build')
        expect(buildhost[:distro]).to match('ubuntu')
        expect(buildhost[:release]).to match('trusty')
      end
    end

    context 'with non-default arguments' do
      it 'returns a host with the desired distribution & release' do
        expect(subject).to receive(:find_source_image)
          .with('debian', '7')
          .and_return(['debian-7-test', 9999])
        expect(subject).to receive(:create_disk)
          .with(/.*/, 9999, 'debian-7-test')
          .and_return('test-disk')
        expect(subject).to receive(:create_instance)
          .with(/.*/, 'test-disk')
          .and_return(server_double)

        buildhost = subject.get(os: 'debian_7')
        expect(buildhost.transports).to match_array(['ssh'])
        expect(buildhost[:username]).to match('build')
        expect(buildhost[:workspace]).to match('/home/build')
        expect(buildhost[:distro]).to match('debian')
        expect(buildhost[:release]).to match('7')
      end
    end
  end

  context 'releasing a build host' do
    let :fog_instance do
      dbl = instance_double(Fog::Compute::Google::Server)
      expect(dbl).to receive(:destroy).and_return(true)

      return dbl
    end

    before do
      expect_any_instance_of(Fog::Compute::Google::Mock)
        .to receive_message_chain('servers.get').and_return(fog_instance)
    end

    it 'releases a build host' do
      buildhost = double(Cyclid::API::Plugins::GoogleHost)
      expect(buildhost).to receive(:[]).with('name').and_return('test')

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

  describe '#find_source_image' do
    let :source_image do
      'ubuntu-1404-trusty-v20161205'
    end

    let :disk_size do
      9999
    end

    let :fog_image do
      dbl = instance_double(Fog::Compute::Google::Image)
      expect(dbl).to receive(:deprecated).and_return(false)
      expect(dbl).to receive(:name).at_least(:once).and_return(source_image)
      expect(dbl).to receive(:disk_size_gb).and_return(disk_size)

      return dbl
    end

    context 'with a valid distribution & release' do
      before do
        expect_any_instance_of(Fog::Compute::Google::Mock)
          .to receive_message_chain('images.all').and_return([fog_image])
      end

      it 'returns a valid disk image' do
        source_image, disk_size = nil
        expect{ source_image, disk_size = subject.send(:find_source_image, 'ubuntu', 'trusty') }
          .to_not raise_error
        expect(source_image).to eq(source_image)
        expect(disk_size).to eq(disk_size)
      end
    end

    context 'with an invalid distribution & release' do
      it 'raises an exception' do
        expect{ subject.send(:find_source_image, 'ubuntu', 'trusty') }.to raise_error(RuntimeError)
      end
    end
  end
end
