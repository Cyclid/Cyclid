# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Simplecov do
  context 'creating a new instance' do
    it 'creates a new instance with a path' do
      expect{ Cyclid::API::Plugins::Simplecov.new(path: '/foo/bar') }.to_not raise_error
    end

    it 'fails if no path is given' do
      expect{ Cyclid::API::Plugins::Simplecov.new }.to raise_error
    end
  end

  let :transport do
    instance_double(Cyclid::API::Plugins::Transport)
  end

  let :log do
    instance_double(Cyclid::API::LogBuffer)
  end

  let :valid_report do
    '{
      "metrics" : {
        "covered_lines" : 2109,
        "covered_percent" : 86.0816326530612,
        "covered_strength" : 7.2925306122449,
        "total_lines" : 2450
      }
    }'
  end

  context 'with a valid Simplecov coverage report' do
    before :each do
      expect(log).to receive(:write)
    end

    it 'reads the report' do
      context = {}

      simplecov = Cyclid::API::Plugins::Simplecov.new(path: '/foo/bar')
      simplecov.prepare(transport: transport, ctx: context)

      expect(transport).to receive(:download)
        .with(instance_of(StringIO), '/foo/bar') { |io, _path| io.write(valid_report) }

      expect(simplecov.perform(log)).to match_array([true, 0])
      expect(context).to include(:simplecov_coverage)
      expect(context[:simplecov_coverage]).to eq('86.08%')
    end
  end

  let :invalid_report do
    '{}'
  end

  context 'with a invalid Simplecov coverage report' do
    before :each do
      expect(log).to receive(:write)
    end

    it 'exits with a failure' do
      context = {}

      simplecov = Cyclid::API::Plugins::Simplecov.new(path: '/foo/bar')
      simplecov.prepare(transport: transport, ctx: context)

      expect(transport).to receive(:download)
        .with(instance_of(StringIO), '/foo/bar') { |io, _path| io.write(invalid_report) }

      expect(simplecov.perform(log)).to match_array([false, 0])
    end
  end
end
