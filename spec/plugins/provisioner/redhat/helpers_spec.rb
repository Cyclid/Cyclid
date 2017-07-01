# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Helpers::Redhat do
  let :dummy_class do
    Class.new { extend Cyclid::API::Plugins::Helpers::Redhat }
  end

  let :transport do
    instance_double(Cyclid::API::Plugins::Transport)
  end

  describe '#install_yum_utils' do
    it 'uses YUM to install the yum-utils package' do
      expect(transport).to receive(:exec).with('yum install -q -y yum-utils', sudo: true)
      expect{ dummy_class.install_yum_utils(transport) }.to_not raise_error
    end
  end

  describe '#import_signing_key' do
    let :key do
      'http://example.com/repository.key'
    end

    it 'uses RPM to install the signing key' do
      expect(transport).to receive(:exec).with("rpm  --import #{key}", sudo: true)
      expect{ dummy_class.import_signing_key(transport, key) }.to_not raise_error
    end
  end

  describe '#yum_groupinstall' do
    let :groups do
      %w(group1 group2)
    end

    it 'uses YUM to install the list of groups' do
      expect(transport).to receive(:exec).with('yum groupinstall  -y "group1" "group2"', sudo: true)
      expect{ dummy_class.yum_groupinstall(transport, groups) }.to_not raise_error
    end
  end

  describe '#yum_install' do
    let :packages do
      %w(package1 package2)
    end

    it 'uses YUM to install the list of packages' do
      expect(transport).to receive(:exec).with("yum install  -y #{packages.join(' ')}", sudo: true)
      expect{ dummy_class.yum_install(transport, packages) }.to_not raise_error
    end
  end

  describe '#yum_add_repo' do
    let :url do
      'http://example.com/repository.repo'
    end

    it 'uses YUM to add the repository' do
      expect(transport).to receive(:exec).with("yum-config-manager  --add-repo #{url}", sudo: true)
      expect{ dummy_class.yum_add_repo(transport, url) }.to_not raise_error
    end
  end
end
