require_relative 'lib/noch'
include NOCH
require 'mock_redis' # only for testing purposes
NOCH.class_variable_set :@@redis, MockRedis.new # only for testing purposes
ok!