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

require 'airlift/command'
require 'airlift/file'


module Airlift
  module Connection
    # Base class for Airlift connection plugins.
    #
    # @since 1.0.0
    class Base
      def initialize(**config)
        @config = config
      end

      attr_reader :config

      # @!group Primary API
      # ===================

      # Create a new command object.
      #
      # @see Airlift::Command#initialize
      # @return [Airlift::Command]
      def command(*cmd, **options)
        Airlift::Command.new(self, *cmd, **options)
      end

      # Create a new file object.
      #
      # @see Airlift::File#initialize
      # @return [Airlift::File]
      def file(path, **options)
        Airlift::File.new(self, path, **options)
      end

      # @!group Command Shortcuts
      # =========================

      # Create a command object with some defaults and run it. All arguments
      # are the same as {#command}.
      #
      # @see #command
      # @return [Airlift::Command]
      def execute(*args)
        command(*args).tap {|cmd| cmd.run_command }
      end

      # Create a command object with some defaults, run it, and raise an
      # excption if it fails. All arguments are the same as {#command}.
      #
      # @see #command
      # @return [Airlift::Command]
      def execute!(*args)
        execute(*args).tap {|cmd| cmd.error! }
      end

      # @!group Abstract API
      # ====================

      # Hook called during plugin loading the first time a plugin is used. Can
      # be used to check installed utilities, config files, etc.
      #
      # @abstract
      # @return [void]
      def verify_dependencies
        # Implemented by subclasses if needed.
      end

      # Download a given path. Yield data as it is available. Return true if the
      # download succeeds and false if it fails.
      #
      # @abstract
      # @param path [String] Path to download.
      # @param block [Proc] Block to yield downloaded data to.
      # @return [Boolean]
      def download_file(path, &block)
        raise NotImplementedError
      end

      # Upload a given path. Yields a callable which can be sent bytes to upload
      # as they are ready. Return true if the upload succeeds and false if it
      # fails.
      #
      # @abstract
      # @param path [String] Path to download.
      # @param block [Proc] Block to yield sender callable.
      # @return [Boolean]
      def upload_file(path, &block)
        raise NotImplementedError
      end

      # Gather file stat data for a path. Return a File::Stat object or something
      # compatible, or nil if the stat fails.
      #
      # @abstract
      # @param path [String] Path to download.
      # @param follow_symlink [Boolean] Follow symlinks or not.
      # @return [Airlift::Stat, File::Stat, nil]
      def stat(path, follow_symlink:)
        raise NotImplementedError
      end

      # Synchronize a local directory to the remote side. This should behave
      # like rsync with the remote side exactly matching the local side in the
      # end. Return true if the sync succeeds and false if it fails.
      #
      # @abstract
      # @param local_path [String] Local path to sync from.
      # @param remote_path [String] Remote path to sync to.
      # @return [Boolean]
      def sync(local_path, remote_path)
        raise NotImplementedError
      end

      # Delete a given path. Return true if the delete succeeds and false if it
      # fails.
      #
      # @param path [String] Path to delete.
      # @return [Boolean]
      def delete(path)
        raise NotImplementedError
      end

      # Tear down any resources that need it to clean up the connection.
      #
      # @abstract
      # @return [void]
      def close
      end

    end
  end
end
