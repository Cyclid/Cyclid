require 'spec_helper'

describe Cyclid.plugins do
  it 'should be a Registry instance' do
    expect(Cyclid.plugins).to be_an_instance_of Cyclid::API::Plugins::Registry
  end
end

describe Cyclid::API::Plugins::Registry do
  context 'creating a new registry' do
    before :all do
      @registry = Cyclid::API::Plugins::Registry.new
    end

    it 'should be empty' do
      expect(@registry.all(Cyclid::API::Plugins::Base)).to match_array([])
    end

    it 'should not find any plugins' do
      expect(@registry.find('test', Cyclid::API::Plugins::Base)).to be_nil
    end
  end

  context 'registering a plugin' do
    class PluginTypeOne < Cyclid::API::Plugins::Base
      def self.name
        'plugin_type_one'
      end

      def self.human_name
        'plugin_type_one'
      end
    end

    class PluginTypeTwo < Cyclid::API::Plugins::Base
      def self.name
        'plugin_type_two'
      end

      def self.human_name
        'plugin_type_two'
      end
    end

    class TestPluginOne < PluginTypeOne
      def self.name
        'test_plugin'
      end
    end

    class TestPluginTwo < PluginTypeTwo
      def self.name
        'test_plugin'
      end
    end

    before :all do
      @registry = Cyclid::API::Plugins::Registry.new
    end

    it 'should register a new plugin' do
      expect{ @registry.register(TestPluginOne) }.to_not raise_error
    end

    it 'should register a plugin of a different type with the same name' do
      expect{ @registry.register(TestPluginTwo) }.to_not raise_error
    end

    it 'should find a registered plugin' do
      expect(@registry.find('test_plugin', PluginTypeOne)).to eq(TestPluginOne)
      expect(@registry.find('test_plugin', PluginTypeTwo)).to eq(TestPluginTwo)
    end

    it "should return nil if it can't find a plugin" do
      expect(@registry.find('non-existent_plugin', PluginTypeOne)).to be_nil
    end

    it 'should find a registered plugin by its human name' do
      expect(@registry.find('test_plugin', 'plugin_type_one')).to eq(TestPluginOne)
      expect(@registry.find('test_plugin', 'plugin_type_two')).to eq(TestPluginTwo)
    end

    it 'should return the registered plugin in the full set' do
      expect(@registry.all(PluginTypeOne)).to match_array([TestPluginOne])
      expect(@registry.all(PluginTypeTwo)).to match_array([TestPluginTwo])
    end
  end
end
