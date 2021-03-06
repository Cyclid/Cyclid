# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Fedora do
  context 'creating a new instance' do
    it 'should create a new instance' do
      expect{ Cyclid::API::Plugins::Fedora.new }.to_not raise_error
    end
  end

  let :transport do
    instance_double(Cyclid::API::Plugins::Transport)
  end

  context 'with a Fedora 21 build host' do
    let :buildhost do
      Cyclid::API::Plugins::BuildHost.new(hostname: 'test.example.com',
                                          release: '21')
    end

    context 'with an empty environment & packages list' do
      it 'should prepare a host' do
        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost) }.to_not raise_error
      end
    end

    context 'with additional HTTP repositories' do
      let :env do
        { repos: [{ url: 'http://example.com/repository.repo',
                    key_url: 'http://example.com/repository.key' }] }
      end

      it 'should configure the host to use the repositories' do
        expect(transport).to receive(:exec).with('yum install -q -y yum-utils', sudo: true)
        expect(transport).to receive(:exec).with('rpm -q --import http://example.com/repository.key',
                                                 sudo: true)
        expect(transport).to receive(:exec).with('yum-config-manager -q --add-repo http://example.com/repository.repo',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with additional RPM repositories' do
      let :env do
        { repos: [{ url: 'http://example.com/repository.rpm',
                    key_url: 'http://example.com/repository.key' }] }
      end

      it 'should configure the host to use the repositories' do
        expect(transport).to receive(:exec).with('yum install -q -y yum-utils', sudo: true)
        expect(transport).to receive(:exec).with('rpm -q --import http://example.com/repository.key',
                                                 sudo: true)
        expect(transport).to receive(:exec).with('yum install -q -y --nogpgcheck http://example.com/repository.rpm',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with package groups' do
      let :env do
        { groups: %w(group1 group2) }
      end

      it 'should install the package groups' do
        expect(transport).to receive(:exec).with('yum groupinstall -q -y "group1" "group2"',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with additional packages' do
      let :env do
        { packages: %w(package1 package2) }
      end

      it 'should install the packages' do
        expect(transport).to receive(:exec).with('yum install -q -y package1 package2', sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end
  end

  context 'with a Fedora 22 build host' do
    let :buildhost do
      Cyclid::API::Plugins::BuildHost.new(hostname: 'test.example.com',
                                          release: '22')
    end

    context 'with an empty environment & packages list' do
      it 'should prepare a host' do
        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost) }.to_not raise_error
      end
    end

    context 'with additional HTTP repositories' do
      let :env do
        { repos: [{ url: 'http://example.com/repository.repo',
                    key_url: 'http://example.com/repository.key' }] }
      end

      it 'should configure the host to use the repositories' do
        expect(transport).to receive(:exec).with("dnf install -q -y 'dnf-command(config-manager)'",
                                                 sudo: true)
        expect(transport).to receive(:exec).with('rpm -q --import http://example.com/repository.key',
                                                 sudo: true)
        expect(transport).to receive(:exec).with('dnf config-manager -q --add-repo http://example.com/repository.repo',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with additional RPM repositories' do
      let :env do
        { repos: [{ url: 'http://example.com/repository.rpm',
                    key_url: 'http://example.com/repository.key' }] }
      end

      it 'should configure the host to use the repositories' do
        expect(transport).to receive(:exec).with("dnf install -q -y 'dnf-command(config-manager)'",
                                                 sudo: true)
        expect(transport).to receive(:exec).with('rpm -q --import http://example.com/repository.key',
                                                 sudo: true)
        expect(transport).to receive(:exec).with('dnf install -q -y http://example.com/repository.rpm',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with package groups' do
      let :env do
        { groups: %w(group1 group2) }
      end

      it 'should install the package groups' do
        expect(transport).to receive(:exec).with('dnf groups install -q -y "group1" "group2"',
                                                 sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end

    context 'with additional packages' do
      let :env do
        { packages: %w(package1 package2) }
      end

      it 'should install the packages' do
        expect(transport).to receive(:exec).with('dnf install -q -y package1 package2', sudo: true)

        provisioner = nil
        expect{ provisioner = Cyclid::API::Plugins::Fedora.new }.to_not raise_error
        expect{ provisioner.prepare(transport, buildhost, env) }.to_not raise_error
      end
    end
  end
end
