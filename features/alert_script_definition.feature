Feature: Alert script definition
  As a user of NOCH
  In order to use its features
  I want to create a script to use it

Scenario: Alert name
  Given I create a script with the name 'my_script.rb' like follows
  """
require_relative 'lib/noch'
include NOCH
require 'mock_redis' # only for testing purposes
NOCH.class_variable_set :@@redis, MockRedis.new # only for testing purposes
ok!
  """
  When I run the script with name 'my_script.rb'
  Then alert name should print 'Alert: `My Script changed from `OK` to `ok` *  *'