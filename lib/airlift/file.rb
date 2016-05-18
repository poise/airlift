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

require 'airlift/errors'


module Airlift
  # Remote file or directory proxy object.
  #
  # @since 1.0.0
  class File
    # Create a proxy object. All data is lazy-loaded so this does very little.
    #
    # @param connection [Airlift::Connection] Connection object to use for
    #   operations.
    # @param path [String] File or directory path.
    # @param follow_symlink [Boolean] Follow symlinks when getting file info.
    def initialize(connection, path, follow_symlink: true)
      @connection = connection
      @path = path
      @follow_symlink = follow_symlink
    end

    # @!group Accessors
    # =================

    # @attribute connection
    #   Connection object to use for operations.
    #   @return [Airlift::Connection]
    attr_reader :connection

    # @attribute path
    #   File or directory path.
    #   @return [String]
    attr_reader :path

    # @attribute follow_symlink
    #   Follow symlinks when getting file info.
    #   @return [Boolean]
    attr_reader :follow_symlink

    # @!group Core API
    # ================

    # Load file content in to a string. Returns nil if the file does not exist
    # or is not readable.
    #
    # @return [String, nil]
    def content
      return @content if defined?(@content)
      buf = ''
      if @connection.download_file(@path) {|data| buf << data }
        @content = buf
      else
        # File wasn't readable.
        @content = nil
      end
    end

    # Upload new file content from a string. Raises an exception if the file
    # could not be written.
    #
    # @param data [String] New file content.
    # @return [void]
    def content=(data)
      @content = data
      @connection.upload_file(@path) {|send| send.call(data) }
    end

    # Gather file metadata information. Returns nil if the file does not exist
    # or is not readable.
    #
    # @return [File::Stat, Airlift::Stat, nil]
    def stat
      return @stat if defined?(@stat)
      @stat = @connection.stat_file(@path, follow_symlink: @follow_symlink)
    end

    # Download to a local path. Returns true if the file was downloaded and
    # false if the file does not exist or is not readable.
    #
    # @param local_path [String] Path to download to.
    # @return [Boolean]
    def download(local_path)
      local_file = ::File.open(local_path, 'wb')
      @connection.download_file(@path) {|data| local_file.write(data) }
    end

    # Upload from a local file. Returns true if the file was uploaded and false
    # if the file could not be written.
    #
    # @param local_path [String] Path to upload from.
    # @return [Boolean]
    def upload(local_path)
      @connection.upload_file(@path) do |send|
        local_file = ::File.open(local_path, 'rb')
        while data = local_file.read(1024)
          send.call(data)
        end
      end
    end

    # Synchronize a local and remote directory. Any new files in the local path
    # will be uploaded and extra files on the remote side will be removed.
    # Returns true if the sync succeeds and false if it fails.
    #
    # @param local_path [String] Path to sync from.
    # @return [Boolean]
    def sync(local_path)
      @connection.sync_files(local_path, @path)
    end

    # Delete a file. Returns true if the file was deleted or false if it was
    # not.
    #
    # @return [Boolean]
    def delete
      @connection.delete_file(@path)
    end

    # @!group Exception API
    # =====================

    # Load file content or raise an exception.
    #
    # @see #content
    def content!
      content.tap do |data|
        raise Errors::FileError.new("Unable to get content for #{@path}") if data.nil?
      end
    end

    # Gather file information or raise an exception.
    #
    # @see #stat
    def stat!
      stat.tap do |data|
        raise Errors::FileError.new("Unable to stat #{@path}") if data.nil?
      end
    end

    # Download file or raise an exception.
    #
    # @see #download
    def download!(local_path)
      download(local_path).tap do |success|
        raise Errors::FileError.new("Unable to download #{@path}") unless success
      end
    end

    # Upload file or raise an exception.
    #
    # @see #upload
    def upload!(local_path)
      upload(local_path).tap do |success|
        raise Errors::FileError.new("Unable to upload #{@path}") unless success
      end
    end

    # Synchronize a local and remote directory or raise an exception.
    #
    # @see #sync
    def sync!(local_path)
      sync(local_path).tap do |success|
        raise Errors::FileError.new("Unable to sync #{@path}") unless success
      end
    end

    # Delete a file or raise an exception.
    #
    # @see #delete
    def delete!(local_path)
      delete(local_path).tap do |success|
        raise Errors::FileError.new("Unable to delete #{@path}") unless success
      end
    end

    # @!group Sugar Helpers
    # =====================

    # Return the proxy corresponding to the unfollowed symlink source for the
    # same path.
    #
    # @return [Airlift::File]
    def link_source
      if @follow_symlink
        self.class.new(@connection, @path, follow_symlink: false)
      else
        self
      end
    end

  end
end
