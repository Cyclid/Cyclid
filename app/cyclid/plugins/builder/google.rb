# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fog/google'
require 'securerandom'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Google build host
      class GoogleHost < BuildHost
        # SSH is the only acceptable Transport
        def transports
          ['ssh']
        end
      end

      # Google builder. Creates Google Compute instances.
      class Google < Builder
        def initialize
          @config = load_google_config(Cyclid.config.plugins)
          Cyclid.logger.debug "config=#{@config.inspect}"
          @api = Fog::Compute.new(provider: 'Google',
                                  google_project: @config[:project],
                                  google_client_email: @config[:client_email],
                                  google_json_key_location: @config[:json_key_location])
        end

        # Create & return a build host
        def get(args = {})
          args.symbolize_keys!

          Cyclid.logger.debug "google: args=#{args}"

          # If there is one, split the 'os' into a 'distro' and 'release'
          if args.key? :os
            match = args[:os].match(/\A(\w*)_(.*)\Z/)
            distro = match[1] if match
            release = match[2] if match
          else
            # No OS was specified; use the default
            # XXX Defaults should be configurable
            distro = 'ubuntu'
            release = 'trusty'
          end

          # Get the instance size, or a default if there isn't one
          size = args[:size] || 'micro'
          machine_type = map_machine_type(size)

          name = create_name

          source_image, disk_size = find_source_image(distro, release)
          disk = create_disk(name, disk_size, source_image)
          instance = create_instance(name, disk, machine_type)

          Cyclid.logger.debug "instance=#{instance.inspect}"

          GoogleHost.new(name: name,
                         host: instance.public_ip_address,
                         username: @config[:username],
                         workspace: "/home/#{@config[:username]}",
                         password: nil,
                         key: @config[:ssh_private_key],
                         distro: distro,
                         release: release)
        end

        # Destroy the build host
        def release(_transport, buildhost)
          name = buildhost[:name]

          instance = @api.servers.get(name)
          raise "instance #{name} does not exist" unless instance

          Cyclid.logger.info "destroying #{name}"
          raise 'failed to destroy instance' unless instance.destroy
        end

        # Plugin metadata
        def self.metadata
          super.merge!(version: Cyclid::Api::VERSION,
                       license: 'Apache-2.0',
                       author: 'Liqwyd Ltd.',
                       homepage: 'http://docs.cyclid.io')
        end

        # Register this plugin
        register_plugin 'google'

        private

        # Load the config for the Google plugin and set defaults if they're not
        # in the config
        def load_google_config(config)
          config.symbolize_keys!

          google_config = config[:google] || {}
          google_config.symbolize_keys!
          Cyclid.logger.debug "config=#{google_config}"

          raise 'the Google project must be provided' \
            unless google_config.key? :project

          raise 'the Google client email must be provided' \
            unless google_config.key? :client_email

          raise 'the JSON key location must be provided' \
            unless google_config.key? :json_key_location

          # Set defaults
          google_config[:zone] = 'us-central1-a' unless google_config.key? :zone
          google_config[:machine_type] = 'f1-micro' unless google_config.key? :machine_type
          google_config[:network] = 'default' unless google_config.key? :network
          google_config[:username] = 'build' unless google_config.key? :username
          google_config[:ssh_private_key] = File.join(%w(/ etc cyclid id_rsa_build)) \
            unless google_config.key? :ssh_private_key
          google_config[:ssh_public_key] = File.join(%w(/ etc cyclid id_rsa_build.pub)) \
            unless google_config.key? :ssh_public_key
          google_config[:instance_name] = 'cyclid-build' \
            unless google_config.key? :instance_name

          return google_config
        end

        # Generate a unique name for the build host
        def create_name
          base = @config[:instance_name]
          "#{base}-#{SecureRandom.hex(16)}"
        end

        # Map the generic size to a machine type
        def map_machine_type(size)
          map = { 'default' => @config[:machine_type],
                  'micro' => 'f1-micro',
                  'mini' => 'g1-small',
                  'small' => 'n1-standard-1',
                  'medium' => 'n1-standard-2',
                  'large' => 'n1-standard-4' }

          map[size]
        end

        # Map the distro & release to a source image
        def find_source_image(distro, release)
          Cyclid.logger.debug 'attempting to find source image'

          source_image = nil
          disk_size = 0

          @api.images.all.each do |image|
            next if image.deprecated

            match = image.name.match(/^#{distro}-((\d*)-(.*)-v.*$|(\d*)-v.*$)/)
            next unless match
            next unless match[2] == release or
                        match[3] == release or
                        match[4] == release

            # Found one
            Cyclid.logger.info "found image #{image.name} for #{distro}:#{release}"
            source_image = image.name
            disk_size = image.disk_size_gb

            break
          end

          # If we didn't find a disk, we have to stop now
          raise "could not find suitable source image for #{distro}:#{release}" \
            unless source_image

          return source_image, disk_size
        end

        # Create a new disk image from the source
        def create_disk(name, size, source_image)
          disk = @api.disks.create(name: name,
                                   size_gb: size,
                                   zone_name: @config[:zone],
                                   source_image: source_image)

          Cyclid.logger.info 'waiting for disk...'
          disk.wait_for { disk.ready? }

          return disk
        end

        # Create a compute instance
        def create_instance(name, disk, machine_type)
          Cyclid.logger.info "creating instance #{name}"
          instance = @api.servers.bootstrap(name: name,
                                            disks: [disk],
                                            machine_type: machine_type,
                                            zone_name: @config[:zone],
                                            network: @config[:network],
                                            username: @config[:username],
                                            public_key_path: @config[:ssh_public_key],
                                            private_key_path: @config[:ssh_private_key],
                                            tags: ['build', 'build-host'])

          device_name = instance.disks[0]['deviceName']
          instance.set_disk_auto_delete(true, device_name)

          instance.wait_for { instance.sshable? }

          return instance
        end
      end
    end
  end
end
