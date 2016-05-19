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


module Airlift
  autoload :File, 'airlift/file'
  autoload :VERSION, 'airlift/version'

  def connect(**options)
    # Convert all options to string keys.
    options = options.inject({}) {|memo, (key, value)| memo[key.to_s] = value; memo }
    # Figure out which plugin to load. If no explicit name is given but a
    # hostname is, use SSH, otherwise use local.
    plugin = options['name'] || (options['hostname'] ? 'ssh' : 'local')
    # Based on Test Kitchen's plugin loader, require the file and load the class.
    first_load = require("airlift/connection/#{plugin}")
    str_const = plugin.split("_").map { |i| i.capitalize }.join
    klass = Airlift::Connection.const_get(str_const)
    object = klass.new(options)
    object.verify_dependencies if first_load
    object
  rescue LoadError, NameError
    raise ClientError,
      "Could not load the '#{plugin}' plugin from the load path." \
        " Please ensure that your plugin is installed as a gem or" \
        " included in your Gemfile if using Bundler."
  end
end
