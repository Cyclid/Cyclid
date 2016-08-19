# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::Github do
  it 'returns the default config' do
    expect(Cyclid::API::Plugins::Github.default_config).to eq('repository_tokens' => [],
                                                              'hmac_secret' => nil)
  end

  it 'returns the config schema' do
    schema = nil
    expect{ schema = Cyclid::API::Plugins::Github.config_schema }.to_not raise_error
    expect(schema).to be_an_instance_of(Array)
    expect(schema.size).to be >= 2

    expect(schema[0]).to be_an_instance_of(Hash)
    expect(schema[0]).to include :name
    expect(schema[0]).to include :type
    expect(schema[0]).to include :description
    expect(schema[0]).to include :default

    expect(schema[1]).to be_an_instance_of(Hash)
    expect(schema[1]).to include :name
    expect(schema[1]).to include :type
    expect(schema[1]).to include :description
    expect(schema[1]).to include :default
  end

  context 'updating the config' do
    before :each do
      @config = Cyclid::API::Plugins::Github.default_config
    end

    it 'adds repository tokens' do
      tokens = [{ 'url' => 'http://example.com/example/test', 'token' => 'abcdefguvwxyz' }]
      new_config = { 'repository_tokens' => tokens }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Github.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'hmac_secret'
      expect(updated_config).to include 'repository_tokens'
      expect(updated_config['repository_tokens']).to match_array(tokens)
    end

    it 'removes repository tokens' do
      # Add a token
      tokens = [{ 'url' => 'http://example.com/example/test', 'token' => 'abcdefguvwxyz' }]
      new_config = { 'repository_tokens' => tokens }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Github.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config['repository_tokens']).to match_array(tokens)

      # Now delete that token
      tokens = [{ 'url' => 'http://example.com/example/test', 'token' => nil }]
      new_config = { 'repository_tokens' => tokens }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Github.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config['repository_tokens']).to match_array([])
    end

    it 'updates the HMAC secret' do
      new_config = { 'hmac_secret' => 'abcdefguvwxyz' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Github.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'hmac_secret'
      expect(updated_config['hmac_secret']).to eq('abcdefguvwxyz')
    end
  end
end
