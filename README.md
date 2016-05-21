# Airlift

[![Build Status](https://img.shields.io/travis/poise/airlift.svg)](https://travis-ci.org/poise/airlift)
[![Gem Version](https://img.shields.io/gem/v/airlift.svg)](https://rubygems.org/gems/airlift)
[![Coverage](https://img.shields.io/codecov/c/github/poise/airlift.svg)](https://codecov.io/github/poise/airlift)
[![Gemnasium](https://img.shields.io/gemnasium/poise/airlift.svg)](https://gemnasium.com/poise/airlift)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A transport abstraction layer for running commands and manipulating files over
SSH, WinRM, and more.

## Quick Start

```ruby
require 'airlift'

# Create a connection.
conn = Airlift.connect('ssh://ec2-user@example.com')
# Run a command.
puts conn.execute!('uname -a').stdout
# Get the content of a file.
puts conn.file('/etc/motd').content
# Upload a file.
conn.file('/tmp/config.rb').upload('config.rb')
```

## `Airlift.connect`

To create a connection object, use `Airlift.connect`. You can specify either
a connection URI, a hash of options, or both. When using the URI style the
scheme will be used as the connection plugin name; the URI's hostname, port,
username, and password will be used as their relevant field, and the query
string will be parsed for additional key/value pairs.

```ruby
# Example of URI style.
Airlift.connect('ssh://me:secret@example.com')
# Example of hash style.
Airlift.connect(name: 'ssh', user: 'me', password: 'secret', host: 'example.com')
```

When using the hash style, if no explicit plugin name is given it will default
to `ssh` if a host if provided or `local` if it is not.

`Airlift.start` can also be passed a block, in which case the connection will
be closed automatically.

```ruby
Airlift.connect('ssh://coderanger.net') do |conn|
  # ...
end
```

## `Airlift::Connection`

The connection object is the core interface to working with the remote system.
The two main methods on it are `command(cmd)` for creating `Airlift::Command` objects
and `file(path)` for creating `Airlift::File` objects.

For convenience two other command methods are provided, `execute(cmd)` will
create a command object and immediately run it, and `execute!(cmd)` will create
a command object, run it, and raise an exception if it fails.

You can use the `tempfile()` method to create a temporary file or directory.

## `Airlift::Command`

The command object contains information about a single command, the parameters
it will be run with and the results of running it. It matches the API of
[`Mixlib::ShellOut`](https://github.com/chef/mixlib-shellout) but some of the
options are not supported (`domain`, `password`, `user`, `group`, `umask`,
and `login`).

Use `conn.command('command to run', options)` to create a new command object.
Once you have the object, call `cmd.run_command` to actually run it and then
you can look in `cmd.stdout`, `cmd.stderr`, and `cmd.exitstatus` for the results.

Additional options on top of the standard `ShellOut` API:
* `sudo` – Boolean for if the command should be run using sudo. *(default:
  connection-level configuration)*
* `sudo_password` – Password for sudo. _NOT IMPLEMENTED_
* `pty` – Request a PTY for the command. *(default: true)*

## Sponsors

Development sponsored by [Bloomberg](http://www.bloomberg.com/company/technology/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2016, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
