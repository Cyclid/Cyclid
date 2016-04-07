require 'yaml'

module Cyclid
  module API
    # Cyclid API configuration
    class Config
      attr_reader :database, :log, :dispatcher, :builder

      def initialize(path)
        @config = YAML.load_file(path)

        @database = @config['database']
        @log = @config['log'] || File.join(%w(/ var log cyclid))
        @dispatcher = @config['dispatcher']
        @builder = @config['builder']
      rescue StandardError => ex
        abort "Failed to load configuration file #{path}: #{ex}"
      end
    end
  end
end
