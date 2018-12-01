# standup-summary

You know the awesome [git-standup](https://github.com/kamranahmedse/git-standup) right? That is heart of this gem.
Standup-Summary pulls all your nested git-standups from directory of choice (eg. work in my case) and shows you number of your commits in given time span and percentage of commits per directory.

## Installation

Just install gem to your global ruby version.

    $ gem install standup-summary

## Usage
Use `standup` in your command line with these options:

| Option      |                             Description                            |
|-------------|:------------------------------------------------------------------:|
| -p, --path  | Sets path to execute git-standup from, relative to your $HOME path |
| -t, --today | Use commits from today                                             |
| -w, --week  | Use commits from this week                                         |
| -m, --month | Use commits from this month                                        |

## Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Todo

- support for ruby controll

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/podruh/standup_summary. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the StandupSummary project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/podruh/standup_summary/blob/master/CODE_OF_CONDUCT.md).
