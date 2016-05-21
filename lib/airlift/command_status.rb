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
  # Duck type for Process::Status because we can't actually create new instances
  # of that (I tried). Only a subset of methods are supported because we don't
  # usually have the full process status.
  #
  # @since 1.0.0
  # @api private
  class CommandStatus
    def initialize(status=nil, pid=nil)
      @status = status
      @pid = pid
    end

    def exited?
     @status && @status < 128
    end

    def exitstatus
      @status
    end

    def pid
      @pid
    end

    def signaled?
      @status && @status >= 128
    end

    def success?
      return nil if @status.nil?
      @status == 0
    end

    def termsig
      if signaled?
        @status - 128
      else
        nil
      end
    end
  end
end
