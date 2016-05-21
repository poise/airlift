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

require 'mixlib/shellout'


module Airlift
  # Helper object to manage command execution.
  #
  # @since 1.0.0
  class Command < Mixlib::ShellOut
    def initialize(connection, *args)
      super(*args)
      @connection = connection
    end

    attr_accessor :sudo
    attr_accessor :sudo_password
    attr_accessor :pty

    # The base class only defines status as an attr_reader, we need to write to
    # it from connection methods.
    # @api private
    attr_writer :status

    def run_command
      # Copy over the default logging from the base class because we can't call
      # it directly.
      if logger
        log_message = (log_tag.nil? ? "" : "#@log_tag ") << "sh(#@command)"
        logger.send(log_level, log_message)
      end

      # Use the low-level connection API to run the command.
      @connection.execute_command(self)
    end

    def parse_options(opts)
      opts.delete_if do |option, setting|
        case option.to_s
        when 'sudo'
          self.sudo = setting
          true
        when 'pty'
          self.pty = setting
          true
        else
          false
        end
      end
      super
    end

    def validate_options(opts)
      %i{domain password user group umask login}.each do |opt|
        raise Errors::CommandError.new("#{opt} is not supported") if send(opt)
      end
    end

  end
end
