Before do |scenario|
  require_relative 'my_alert_script_template'

  # Mocking Redis Server
  NOCH.class_variable_set :@@redis, MockRedis.new # mocking redis for testing purposes

  # Mocking slack
  NOCH.class_variable_set :@@client, MockSlack.new

end
at_exit do
  begin
    File.delete 'my_script.rb'
  rescue
  end
end