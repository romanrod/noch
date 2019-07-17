ENV['SLACK_API_TOKEN']='FAKE-SLACK-API-TOKEN'
require 'mock_redis'
require 'byebug'

require_relative 'my_alert_script'

NOCH.class_variable_set :@@redis, MockRedis.new # mocking redis for testing purposes


# Mocking slack responses
Slack::Web::Config.endpoint='http://mockbin.org/status/200'