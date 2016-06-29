#
# Copyright 2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'uri'


module Airlift
  autoload :Errors, 'airlift/errors'
  autoload :File, 'airlift/file'
  autoload :VERSION, 'airlift/version'

  class << self
    def connect(uri=nil, **config, &block)
      config = parse_configuration(uri, **config)
      begin
        plugin = config[:name] || (config[:host] ? 'ssh' : 'local')
        # Based on Test Kitchen's plugin loader, require the file and load the class.
        first_load = require("airlift/connection/#{plugin}")
        str_const = plugin.split("_").map { |i| i.capitalize }.join
        klass = Airlift::Connection.const_get(str_const)
        connection = klass.new(**config)
        connection.verify_dependencies if first_load
        if block
          rv = block.call(connection)
          connection.close
          rv
        else
          connection
        end
      rescue ::LoadError, ::NameError
        raise Errors::LoadError,
          "Could not load the '#{plugin}' plugin from the load path." \
            " Please ensure that your plugin is installed as a gem or" \
            " included in your Gemfile if using Bundler."
      end
    end

    private

    def parse_configuration(uri=nil, **config)
      # Convert all config to symbol keys.
      config = config.inject({}) {|memo, (key, value)| memo[key.to_sym] = value; memo }
      # Parse a URI if given.
      if uri
        parsed_uri = URI(uri)
        raise Errors::AirliftError.new("Invalid URI #{uri}, scheme is required.") unless parsed_uri.scheme
        uri_config = {name: parsed_uri.scheme}
        uri_config[:host] = parsed_uri.host if parsed_uri.host && !parsed_uri.host.empty?
        uri_config[:port] = parsed_uri.port if parsed_uri.port && !parsed_uri.port.empty?
        uri_config[:user] = parsed_uri.user if parsed_uri.user && !parsed_uri.user.empty?
        uri_config[:password] = parsed_uri.password if parsed_uri.password && !parsed_uri.password.empty?
        URI.decode_www_form(parsed_uri.query || '').each do |key, value|
          # Safe YAML parsing to support simple Ruby types.
          uri_config[key.to_sym] = YAML.safe_load(value)
        end
        # Explicit keywork arguments take priority over the URI.
        config = uri_config.merge(config)
      end
      # Some common fixups for all plugins because they happen a lot.
      config[:name] = config.delete(:plugin) if config.include?(:plugin)
      config[:user] = config.delete(:username) if config.include?(:username)
      config[:host] = config.delete(:hostname) if config.include?(:hostname)
      # Figure out which plugin to load. If no explicit name is given but a
      # hostname is, use SSH, otherwise use local.
      config
    end

  end
end
