# NOCH

NOCH stands for Notify On CHange.
Suppose you have a job running scheduled to check something. Every execution will have a result and you'll want to notify when something go wrong.
Ok, if several times the result is the same...Do you want to notify every time the job run for the same result?
If you do not, NOCH can help you with this kind of situations.
NOCH will notify when status change its value by using three simple methods

`ok!`

`warning!`

`critical!`

Notifications are sent to Slack channel

## Requirements

This uses [Redis](https://redis.io/) to save states. If your Redis runs out of the job run, you have to pass `REDIS_HOST` and `REDIS_PORT`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'noch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install noch

## Usage

Create a file with a name you want.

```
# my_alert_script.rb

# SLACK 00000000000000000
include NOCH

if everything_is_ok?
  ok!
else
  critical! 'mmlpqtp'
end

```

Run it!

SLACK_API_TOKEN=<your_slack_api_token> REDIS_HOST=<your-redis-host> REDIS_PORT=<your-redis-port> ruby my_alert_script.rb

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/romanrod/noch.
