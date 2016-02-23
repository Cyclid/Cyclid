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
          args.symbolize_keys!

          # At a bear minimum there has to be a command to execute.
          return false unless args.include? :cmd

          # The command & arguments can either be passed seperately, with the
          # args as an array, or as a single string which we then split into
          # a command & array of args.
          if args.include? :args
            @cmd = args[:cmd]
            @args = args[:args]
          else
            cmd_args = args[:cmd].split
            @cmd = cmd_args.shift
            @args = cmd_args
          end

          Cyclid.logger.debug "cmd: '#{@cmd}' args: #{@args}"

          @env = args[:env] if args.include? :env
          @path = args[:path] if args.include? :path

          #super
        end

        # Note that we don't need to explicitly use the log for transport
        # related tasks as the transport will take of writing any data from the
        # commands into the log. The log is still passed in to perform() so that
        # plugins which run locally can write their own data to it. 
        def perform(log)
          @transport.export_env @env unless @env.nil?

          success = @transport.exec("#{@cmd} #{@args.join(' ')}", @path)

          [success, @transport.exit_code]
        end

        # Register this plugin
        register_plugin 'command'
      end
    end
  end
end
