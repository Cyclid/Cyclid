# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Mist build host
      class MistHost < BuildHost
        # SSH is the only acceptable Transport
        def transports
          ['ssh']
        end 
      end

      # Mist builder. Calls out to Mist to obtain a build host instance.
      class Mist < Builder
        def initialize(args = {})
          args.symbolize_keys!

          @os = args[:os]
        end

        def get(args = {})
          # XXX Just return a random host from these two, for testing
          hosts = ['r1','r2']
          MistHost.new(hostname: hosts.sample, username: 'sys-ops', password: nil, distro: 'ubuntu')
        end
 
        def prepare(transport, buildhost, env = {})
          distro = buildhost[:distro]

          # XXX This is, clearly, horrible.
          if env.key? :repos
            if distro == 'ubuntu' || distro == 'debian'
              env[:repos].each do |repo|
                if distro == 'ubuntu'
                  transport.exec "sudo add-apt-repository #{repo}"
                elsif distro == 'debian'
                  # XXX
                end
              end

              transport.exec 'sudo apt-get update'

              env[:packages].each do |package|
                transport.exec "sudo apt-get install -y #{package}"
              end
            elsif distro == 'redhat' || distro == 'fedora'
              env[:packages].each do |package|
                transport.exec "sudo yum install #{package}"
              end
            end
          end
        end

        def release(transport, buildhost)
          transport.exec "echo sudo shutdown -h now"
        end

        # Register this plugin
        register_plugin 'mist'
      end
    end
  end
end
