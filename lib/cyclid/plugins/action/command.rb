# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Command plugin
      class Command < Action 

        Cyclid.logger.debug 'in the Command plugin'

        def initialize(args={})
          return false unless args.include? :command

          cmd_args = args[:command].split
          @command = cmd_args.shift
          @args = cmd_args

          Cyclid.logger.debug "command: '#{@command}' args: #{@args}"

          @env = args[:env] if args.include? :env
          @cwd = args[:cwd] if args.include? :cwd

          super
        end

        # Note that we don't need to explicitly use the log for transport
        # related tasks as the transport will take of writing any data from the
        # commands into the log. The log is still passed in to perform() so that
        # plugins which run locally can write their own data to it. 
        def perform(log)
          @transport.export_env @env unless @env.nil?
          @transport.exec "cd #{@cwd}" unless @cwd.nil?

          @transport.exec "#{@command} #{@args.join(' ')}"
        end

        # Register this plugin
        register_plugin 'command'
      end
    end
  end
end
