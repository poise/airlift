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
  # A mostly File::Stat-compatible wrapper for file stat data.
  #
  # @since 1.0.0
  # @see File::Stat
  class Stat
    # Create a stat object. Only path and ftype are required, all other fields
    # are optional and system-dependent. See individual accessors for more
    # information about each value.
    def initialize(path, ftype, atime: nil, birthtime: nil, blksize: nil, blocks: nil, ctime: nil, dev: nil,
                   dev_major: nil, dev_minor: nil, gid: nil, ino: nil, mode: nil, mtime: nil, nlink: nil, rdev: nil,
                   rdev_major: nil, rdev_minor: nil, size: nil, uid: nil)
      @path = path
      @ftype = ftype
      @atime = atime
      @birthtime = birthtime
      @blksize = blksize
      @blocks = blocks
      @ctime = ctime
      @dev = dev
      @dev_major = dev_major
      @dev_minor = dev_minor
      @gid = gid
      @ino = ino
      @mode = mode
      @mtime = mtime
      @nlink = nlink
      @rdev = rdev
      @rdev_major = rdev_major
      @rdev_minor = rdev_minor
      @size = size
      @uid = uid
    end

    attr_reader :path
    attr_reader :ftype
    attr_reader :atime
    attr_reader :birthtime
    attr_reader :blksize
    attr_reader :blocks
    attr_reader :ctime
    attr_reader :dev
    attr_reader :dev_major
    attr_reader :dev_minor
    attr_reader :gid
    attr_reader :ino
    attr_reader :mode
    attr_reader :mtime
    attr_reader :nlink
    attr_reader :rdev
    attr_reader :rdev_major
    attr_reader :rdev_minor
    attr_reader :size
    attr_reader :uid

    # Compare two stat objects my comparing modification times.
    #
    # @param other [Airlift::Stat, File::Stat]
    # @return [Integer, nil]
    def <=>(other)
      if other.respond_to?(:mtime)
        mtime <=> other.mtime
      else
        nil
      end
    end

    def blockdev?
      ftype == 'characterSpecial'
    end

    def chardev?
      ftype == 'blockSpecial'
    end

    def directory?
      ftype == 'directory'
    end

    def executable?
      raise NotImplementedError
    end

    def executable_real?
      raise NotImplementedError
    end

    def file?
      ftype == 'file'
    end

    def grpowned?
      raise NotImplementedError
    end

    def owned?
      raise NotImplementedError
    end

    def pipe?
      ftype == 'fifo'
    end

    def readable?
      raise NotImplementedError
    end

    def readable_real?
      raise NotImplementedError
    end

    def setgid?
      mode && !!(mode & 02000)
    end

    def setuid?
      mode && !!(mode & 04000)
    end

    def socket?
      ftype == 'socket'
    end

    def sticky?
      mode && !!(mode & 01000)
    end

    def symlink?
      ftype == 'link'
    end

    def world_readable?
      raise NotImplementedError # TODO this could be implemented.
    end

    def world_writable?
      raise NotImplementedError # TODO this could be implemented.
    end

    def writable?
      raise NotImplementedError
    end

    def writable_real?
      raise NotImplementedError
    end

    def zero?
      size == 0
    end
  end
end
