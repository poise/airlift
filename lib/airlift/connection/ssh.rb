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

require 'shellwords'

require 'net/ssh'
require 'net/sftp'

require 'airlift/command_status'
require 'airlift/connection/base'
require 'airlift/errors'
require 'airlift/stat'


module Airlift
  module Connection
    # Connection plugin for running via SSH.
    #
    # @since 1.0.0
    class Ssh < Base
      DEFAULT_READ_SIZE = 32_000

      def initialize(*args)
        super
        @host = config.delete(:host)
      end

      # (see Base#execute_command)
      def execute_command(cmd)
        command_string = cmd.command
        # convert to a single string.
        command_string = Shellwords.join(command_string) if command_string.is_a?(Array)
        # Call cd if we have a working directory to use.
        # TODO The use of sh -c could result in extra unwanted variable interpoation.
        command_string = "sh -c #{Shellwords.escape("cd '#{cmd.cwd}' && exec #{command_string}")}" if cmd.cwd
        # Set any needed environment variables.
        command_string = "env #{cmd.environment.map {|k,v| "#{k}=#v}" }.join(' ')} #{command_string}" unless cmd.environment.empty?
        # Set things up for sudo.
        if cmd.sudo
          if cmd.sudo_password
            raise "not doing this yet"
          else
            # TODO Do we want to sh -c here too?
            command_string = "sudo #{command_string}"
          end
        end

        channel = ssh_connection.open_channel do |ch|
          ch.exec command_string do |_, success|
            raise Errors::CommandError("could not start ssh command execution") unless success

            # Request a PTY to be allocated if needed.
            ch.request_pty if cmd.pty

            # Send anything needed to stdin.
            ch.send_data(cmd.input) if cmd.input

            # Callback for stdout data.
            ch.on_data do |_, data|
              cmd.stdout << data
              cmd.live_stdout << data if cmd.live_stdout
            end

            # Callback for stderr data (mostly).
            ch.on_extended_data do |_, type, data|
              # Just in case someone does something wonky, SSH doesn't actually
              # define any other types but who knows.
              if type == 1
                cmd.stderr << data
                cmd.live_stderr << data if cmd.live_stderr
              end
            end

            # Callback for getting the exit status.
            ch.on_request('exit-status') do |_, data|
              cmd.status = CommandStatus.new(data.read_long)
            end

            # Implement this too but I'm not clear on when it actually gets used
            # by OpenSSH instead of exit-status.
            ch.on_request('exit-signal') do |_, data|
              cmd.status = CommandStatus.new(data.read_long)
            end
          end
        end
        channel.wait
      end

      # (see Base#download_file)
      def download_file(path, &block)
        handle = sftp_connection.open!(path)
        offset = 0
        read_size = DEFAULT_READ_SIZE # TODO customize this via an option.
        while buf = sftp_connection.read!(handle, offset, read_size)
          block.call(buf)
          offset += read_size
        end
        sftp_connection.close!(handle) # TODO This should get an ensure
      rescue Net::SFTP::StatusException
        false
      end

      # (see Base#upload_file)
      def upload_file(path, &block)
        handle = sftp_connection.open!(path)
        offset = 0
        writer_proc = Proc.new do |data|
          sftp_connection.write!(handle, offset, data)
          offset += data.length
        end
        block.call(writer_proc)
        sftp_connection.close!(handle) # TODO This should get an ensure
      rescue Net::SFTP::StatusException
        false
      end

      # (see Base#stat)
      def stat(path, follow_symlink:)
        attrs = if follow_symlink
          sftp_connection.stat!(path)
        else
          sftp_connection.lstat!(path)
        end
        # Map SFTP constants to Stat names.
        ftype = case attrs.type
        when Net::SFTP::Protocol::V01::Attributes::T_REGULAR
          'file'
        when Net::SFTP::Protocol::V01::Attributes::T_DIRECTORY
          'directory'
        when Net::SFTP::Protocol::V01::Attributes::T_SYMLINK
          'link'
        when Net::SFTP::Protocol::V01::Attributes::T_SOCKET
          'socket'
        when Net::SFTP::Protocol::V01::Attributes::T_CHAR_DEVICE
          'characterSpecial'
        when Net::SFTP::Protocol::V01::Attributes::T_BLOCK_DEVICE
          'blockSpecial'
        when Net::SFTP::Protocol::V01::Attributes::T_FIFO
          'fifo'
        else
          # T_SPECIAL ends up here too for lack of anything better to do.
          'unknown'
        end
        # The respond_to? checks are for v04 or v06 attributes. OpenSSH only
        # supports V03 so it is unlikely these will ever be available but we
        # at least try.
        Airlift::Stat.new(path, ftype, {
          atime: attrs.atime,
          birthtime: attrs.respond_to?(:createtime) ? attrs.createtime : nil,
          ctime: attrs.respond_to?(:ctime) ? attrs.ctime : nil,
          gid: attrs.gid,
          group: attrs.group,
          mode: attrs.permissions,
          mtime: attrs.mtime,
          nlink: attrs.respond_to?(:link_count) ? attrs.link_count : nil,
          size: attrs.size,
          uid: attrs.uid,
          user: attrs.owner,
        })
      rescue Net::SFTP::StatusException
        false
      end

      # (see Base#sync)
      def sync(local_path, remote_path)
        raise 'boom'
      end

      # (see Base#delete)
      def delete(path)
        sftp_connection.remove!(path)
        true
      rescue Net::SFTP::StatusException
        false
      end

      # (see Base#close)
      def close
        # Shut down SFTP. Not strictly needed, but it feels cleaner.
        if @sftp_connection
          # TODO Should this call loop until any pending ops finish? Could
          # potentially save us some cycles by making the handle closes non-blocking.
          @sftp_connection.close_channel
          @sftp_connection = nil
        end
        # Shut down SSH.
        if @ssh_connection
          @ssh_connection.shutdown
          @ssh_connection = nil
        end
      end

      private

      def ssh_connection
        @ssh_connection ||= Net::SSH.start(@host, config[:user], config[:ssh_options] || {})
      end

      def sftp_connection
        @sftp_connection ||= Net::SFTP::Session.new(ssh_connection).connect!
      end

    end
  end
end
