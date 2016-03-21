require 'spec_helper'

describe Cyclid::API::Plugins::Base do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Base.human_name).to eq('base')
  end

  context 'without a configuration' do
    it 'should return an empty default config' do
      expect(Cyclid::API::Plugins::Base.default_config).to be {}
    end

    it 'should return an empty config schema' do
      expect(Cyclid::API::Plugins::Base.config_schema).to be {}
    end

    it 'will refuse to store a change to the config' do
      expect(Cyclid::API::Plugins::Base.update_config({}, a: 1, b: 2)).to be false
    end
  end

  context 'registering a plugin' do
    before :all do
      @plugins = Cyclid.plugins
      @registry = Cyclid::API::Plugins::Registry.new
      Cyclid.plugins = @registry
    end

    after :all do
      Cyclid.plugins = @plugins
    end

    it 'should register the plugin' do
      expect do
        class PluginTypeOne < Cyclid::API::Plugins::Base
          def self.name
            'plugin_type_one'
          end

          def self.human_name
            'plugin_type_one'
          end
        end

        class TestPluginOne < PluginTypeOne
          def self.name
            'test_plugin'
          end

          register_plugin 'plugin_type_one'
        end
      end.to_not raise_error
      expect(@registry.all(PluginTypeOne)).to match_array([TestPluginOne])
    end
  end
end
