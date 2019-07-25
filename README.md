# NOCH

NOCH stands for Notify On CHange.
Suppose you have a job running scheduled to check something. Every execution will have a result and you'll want to notify when something go wrong.
Ok, if several times the result is the same...Do you want to notify every time the job run for the same result?
If you do not, NOCH can help you with this kind of situations.
NOCH will notify when status change its value by using three simple methods

`ok!`

`warning!`

`critical!`

`skip!`

Notifications about the change of the status are sent to Slack channel and or Telegram group
You can send a customized message to each method.
And data can be saved

Sending only a message:

`warning! 'Value is higher than 50'`

Sending message and data

`critical! message: 'System outage', data:{ status: '504'}`



## Requirements

This uses [Redis](https://redis.io/) to save states. 

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
# TELEGRAM 111111111111

include NOCH

if everything_is_ok?
  ok! "We are rocking!"
else
  critical! message: 'mmlpqtp', data: {pasaron: 'cosas'}
end

```

Run it!

TELEGRAM_TOKEN=<your_telegram_bot_token> TELEGRAM_USER=<your-telegram-user> SLACK_API_TOKEN=<your_slack_api_token> REDIS_HOST=<your-redis-host> REDIS_PORT=<your-redis-port> ruby my_alert_script.rb

## Test

Just run `rake test` to run the tests and ensure all pass.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/romanrod/noch.
