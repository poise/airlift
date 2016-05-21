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

require 'etc'

require 'mixlib/shellout'

require 'airlift/connection/base'


module Airlift
  module Connection
    # Connection plugin for local command execution and file operations.
    #
    # @since 1.0.0
    class Local < Base
      # (see Base#execute_command)
      def execute_command(cmd)
        # Yo dawg, I heard you like commands in your commands.
        local_cmd = Mixlib::ShellOut.new(cmd.command,
          cwd: cmd.cwd, timeout: cmd.timeout, returns: cmd.valid_exit_codes,
          live_stdout: cmd.live_stdout, live_stderr: cmd.live_stderr,
          input: cmd.input, logger: cmd.logger, log_level: cmd.log_level,
          log_tag: cmd.log_tag, environment: cmd.environment,
        )
        local_cmd.run_command
        cmd.stdout << local_cmd.stdout
        cmd.stderr << local_cmd.stderr
        cmd.status = local_cmd.status
      end

      # (see Base#download_file)
      def download_file(path, &block)
        return false unless ::File.readable?(path)
        ::File.open(path, 'rb') do |fd|
          while buf = fd.read(4096)
            block.call(buf)
          end
        end
        true
      end

      # (see Base#upload_file)
      def upload_file(path, &block)
        return false unless ::File.writable?(path)
        ::File.open(path, 'wb') do |fd|
          block.call(Proc.new {|data| fd.write(data) })
        end
        true
      end

      # (see Base#stat)
      def stat(path, follow_symlink:)
        if follow_symlink
          ::File.stat(path)
        else
          ::File.lstat(path)
        end.tap do |stat|
          # Define our two extension methods.
          group = stat.gid && Etc.getgrgid(stat.gid).name
          user = stat.uid && Etc.getpwuid(stat.uid).name
          stat.define_singleton_method(:group) { group }
          stat.define_singleton_method(:user) { user }
        end
      rescue SystemCallError
        nil
      end

      # (see Base#sync)
      def sync(local_path, remote_path)
        raise 'boom'
      end

      # (see Base#delete)
      def delete(path)
        ::File.unlink(path)
        true
      rescue SystemCallError
        false
      end

    end
  end
end
