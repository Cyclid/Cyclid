# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::DockerApi do
  let :log do
    instance_double(Cyclid::API::LogBuffer)
  end

  let :container do
    instance_double(::Docker::Container)
  end

  let :host do
    '123456789'
  end

  let :success do
    [0, 0, 0]
  end

  let :failure do
    [0, 0, 1]
  end

  before :each do
    c = class_double(::Docker::Container).as_stubbed_const
    expect(c).to receive(:get).with(host).and_return(container)
  end

  context 'executing commands' do
    context 'with a non-root user' do
      let :args do
        { host: host,
          log: log,
          ctx: { username: 'test' } }
      end

      it 'should create a new instance' do
        expect{ Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
      end

      context 'with no environment variables' do
        it 'should execute a command that exits successfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', '/bin/true'],
                                                   wait: 300).and_return(success)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect(t.exec('/bin/true')).to be true
        end

        it 'should execute a command that exits unsuccessfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', '/bin/false'],
                                                   wait: 300).and_return(failure)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect(t.exec('/bin/false')).to be false
        end
      end

      context 'with environment variables' do
        let :env do
          { 'test' => 'example' }
        end

        # rubocop:disable LineLength
        it 'should execute a command that exits successfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', 'export TEST="example";/bin/true'],
                                                   wait: 300).and_return(success)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect{ t.export_env(env) }.to_not raise_error
          expect(t.exec('/bin/true')).to be true
        end

        it 'should execute a command that exits unsuccessfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', 'export TEST="example";/bin/false'],
                                                   wait: 300).and_return(failure)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect{ t.export_env(env) }.to_not raise_error
          expect(t.exec('/bin/false')).to be false
        end
        # rubocop:enable LineLength
      end
    end

    context 'with a root user' do
      let :args do
        { host: host,
          log: log,
          ctx: { username: 'root' } }
      end

      it 'should create a new instance' do
        expect{ Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
      end

      context 'with no environment variables' do
        it 'should execute a command that exits successfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', '/bin/true'],
                                                   wait: 300).and_return(success)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect(t.exec('/bin/true')).to be true
        end

        it 'should execute a command that exits unsuccessfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', '/bin/false'],
                                                   wait: 300).and_return(failure)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect(t.exec('/bin/false')).to be false
        end
      end

      context 'with environment variables' do
        let :env do
          { 'test' => 'example' }
        end

        # rubocop:disable LineLength
        it 'should execute a command that exits successfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', 'export TEST="example";/bin/true'],
                                                   wait: 300).and_return(success)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect{ t.export_env(env) }.to_not raise_error
          expect(t.exec('/bin/true')).to be true
        end

        it 'should execute a command that exits unsuccessfully' do
          expect(container).to receive(:exec).with(['sh', '-l', '-c', 'export TEST="example";/bin/false'],
                                                   wait: 300).and_return(failure)

          t = nil
          expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
          expect{ t.export_env(env) }.to_not raise_error
          expect(t.exec('/bin/false')).to be false
        end
        # rubocop:enable LineLength
      end
    end
  end

  context 'transferring files' do
    let :args do
      { host: host,
        log: log,
        ctx: { username: 'test' } }
    end

    it 'should upload a file' do
      expect(container).to receive(:store_file).with('/path/to/file', 'data').and_return(true)

      s = StringIO.new('data')
      t = nil
      expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
      expect(t.upload(s, '/path/to/file')).to be true
    end

    it 'should download a file' do
      expect(container).to receive(:read_file).with('/path/to/file').and_return('data')

      s = StringIO.new
      t = nil
      expect{ t = Cyclid::API::Plugins::DockerApi.new(args) }.to_not raise_error
      t.download(s, '/path/to/file')
      expect(s.string).to eq 'data'
    end
  end
end
