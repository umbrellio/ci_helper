# CIHelper   [![Actions Status](https://github.com/umbrellio/ci_helper/workflows/Ruby/badge.svg)](https://github.com/umbrellio/ci_helper/actions) [![Coverage Status](https://coveralls.io/repos/github/umbrellio/ci_helper/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/ci_helper?branch=master) [![Gem Version](https://badge.fury.io/rb/ci-helper.svg)](https://badge.fury.io/rb/ci-helper)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ci-helper", require: false
```

And then execute:
```bash
$ bundle install
```
Or install it yourself as:
```bash
$ gem install ci_helper
```

## Usage

### Command Line

You can use this gem as command line utility. For example, to lint project by rubocop,
execute the following command in the project root:
```bash
$ ci-helper RubocopLint # Here's RubocopLint is a command
```

A command can accept list of options (parameters). Option values are passed through flags.
For example, the BundlerAudit command accepts the ignored_advisories option
You can set a value of this option by setting the flag `--ignored-advisories ignored-advisory`.
It should be noted that all hyphens in flag names are automatically replaced with underscores.
```bash
$ ci-helper BundlerAudit --ignored-advisories first,second
```

List of available commands:

* **BundlerAudit** — executes `bundler-audit`. Accepted flags: `--ignored-advisories`.
    * `--ignored-advisories [values]` — accepts advisory codes, delimited by comma.
* **CheckDBDevelopment** — executes rails db commands (`db:drop`, `db:create`, `db:migrate`)
    and seeds database. Does not accept flags.
* **CheckDBRollback** — executes rails db commands with additional command
    `db:rollback_new_migrations`, which rollbacks migrations,
    added in tested branch. Does not accept flags.
* **RubocopLint** — executes rubocop linter. Does not accept flags.
* **RunSpecs** — executes `rspec` in project root.
Accepted flags: `--node-index`, `node-total`, `with-database`, `split-resultset`.
    * `--node-index` — if you run specs in parallel in CI, then you might use this flag.
    * `--node-total` — if you run specs in parallel in CI, then you might use this flag.
    * `--with-database` — if you want to prepare database before executing specs,
        you should set this flag to `true`.
    * `--split-resultset` — if you run specs in parallel in CI,
        then you might use this flag to `true`. If this flag set to true,
        final `.resultset.json` will be renamed to `.resultset.#{node_index}.json`

### Script

Also, you can write your own script, which can executes this commands by calling classes:
`CIHelper::Commands::#{command_name}`. For example,
if you want to execute `RunSpecs` command in your script, you can write following lines:
```ruby
begin
  CIHelper::Commands::RunSpecs.call!(with_database: "true") # returned value is exit code.
rescue CIHelper::Commands::Error => e # Command raise error with this class if something went wrong.
  abort e.message
end
```

## Adding your own commands

You can write plugins (gems) that add new commands.
You just need create gem with following structure:
```
- lib
  - ci_helper
    - commands
      - cool_command.rb
```

Where your `CoolCoomand` class may look something like this:
```ruby
module CIHelper
  module Commands
    class CoolCommand < BaseCommand
      def call
        execute("ls #{options[:cool_options]}")
      end
    end
  end
end
```

Then you add your gem to a Gemfile:
```ruby
gem "ci-helper", require: false
gem "ci-helper-plugin-gem", require: false
```

And now, you can use your custom command with command line tool:
```bash
$ ci-helper CoolCommand --cool-options option_value
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbrellio/ci_helper.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## License

Released under MIT License.

## Authors

Created by Ivan Chernov.

<a href="https://github.com/umbrellio/">
<img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
