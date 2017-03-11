# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Cobertura do
  context 'creating a new instance' do
    it 'creates a new instance with a path' do
      expect{ Cyclid::API::Plugins::Cobertura.new(path: '/foo/bar') }.to_not raise_error
    end

    it 'fails if no path is given' do
      expect{ Cyclid::API::Plugins::Cobertura.new }.to raise_error
    end
  end

  let :transport do
    instance_double(Cyclid::API::Plugins::Transport)
  end

  let :log do
    instance_double(Cyclid::API::LogBuffer)
  end

  # Thanks, Jenkins!
  #
  # https://raw.githubusercontent.com/jenkinsci/cobertura-plugin/master/src/test/resources/hudson/plugins/cobertura/coverage-with-data.xml
  let :valid_report do
    '<?xml version="1.0"?>
     <coverage line-rate="0.9" branch-rate="0.75" version="1.9" timestamp="1187350905008">
     </coverage>'
  end

  context 'with a valid Cobertura coverage report' do
    before :each do
      expect(log).to receive(:write)
    end

    it 'reads the report' do
      context = {}

      cobertura = Cyclid::API::Plugins::Cobertura.new(path: '/foo/bar')
      cobertura.prepare(transport: transport, ctx: context)

      expect(transport).to receive(:download)
        .with(instance_of(StringIO), '/foo/bar') { |io, _path| io.write(valid_report) }

      expect(cobertura.perform(log)).to match_array([true, 0])
      expect(context).to include(:cobertura_line_rate)
      expect(context[:cobertura_line_rate]).to eq('90.0%')

      expect(context).to include(:cobertura_branch_rate)
      expect(context[:cobertura_branch_rate]).to eq('75.0%')
    end
  end

  let :invalid_report do
    '<?xml version="1.0"?>'
  end

  context 'with a invalid Cobertura coverage report' do
    before :each do
      expect(log).to receive(:write)
    end

    it 'exits with a failure' do
      context = {}

      cobertura = Cyclid::API::Plugins::Cobertura.new(path: '/foo/bar')
      cobertura.prepare(transport: transport, ctx: context)

      expect(transport).to receive(:download)
        .with(instance_of(StringIO), '/foo/bar') { |io, _path| io.write(invalid_report) }

      expect(cobertura.perform(log)).to match_array([false, 0])
    end
  end
end
