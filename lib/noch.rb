require "NOCH/version"
require 'slack-ruby-client'
require 'redis'

module NOCH
  
  class Error < StandardError; end

  DEFAULT = {
    "status" => "unknown",
    "last_change" => nil,
    "data" => nil
  }
  
  def self.included(base)
    @@alert_file = caller.select{|l| l.include? "`include'"}.first.split(".").first
    @@alert_name = @@alert_file.split('/').last.split('_').map{|w| w.capitalize}.join(" ")
    @@redis_host = ENV['REDIS_HOST'] || 'localhost'
    @@redis_port = ENV['REDIS_PORT'] || '6379'
    @@redis ||= ::Redis.new(host: @@redis_host, port: @@redis_port)
    ::Slack.configure do |config|
      raise Error.new('SLACK_API_TOKEN not defined') unless ENV['SLACK_API_TOKEN']
      config.token = ENV['SLACK_API_TOKEN']
    end
    @@client = ::Slack::Web::Client.new
  end

  def self.alert_name
    @@alert_name
  end


  def self.changed to
    if (current = self.get_status)
      byebug
      current_status = ::JSON.parse(current)['status']
      current_status if current_status != to
    else
      NOCH.create_object
    end
  end

  def self.get_status
    @@redis.get(@@alert_name)
  end

  def self.evaluate_for what, message = nil, data = nil
    raise "Unknown status #{what}. Allowed: ['ok','warning','critical','skip']" unless ['ok','warning','critical','skip'].include? what
    byebug
    if (from = self.changed what)
      self.set what, message, data
      self.notify(from, what, message, data) unless what == 'skip'
    end
  end

  def self.create_object
    @@redis.set @@alert_name, DEFAULT.to_json
  end

  def self.set to, message = nil, data = nil
    data = {
      'status' => to,
      'last_change' => Time.now,
      'message' => message,
      'data' => data
    }
    @@redis.set @@alert_name, data.to_json
  end

  # notifications
  def self.notify from, to, message, data = nil
    string = "Alert: `#{@@alert_name} changed from `#{from}` to `#{to}` * #{message} *"
    string += "
    
    Data: 
    #{data}
    " if data
    print string
    self.send_slack(string, self.slack)
  end

  def self.send_slack message = nil, slack_channel = nil
    if slack_channel
      @@client.auth_test
      if message and slack_channel
        begin
          puts "Enviando: #{message}
          to: #{slack_channel}"
          @@client.chat_postMessage(channel: slack_channel, text: 'Hello World', as_user: true)
          true
        rescue
          puts "Error sending message to slack channel #{slack_channel}"
          false
        end
      end
    end
  end

  def self.slack
    self.matched_line("SLACK")&.strip
  end

  # To get config token and values, e.g for slack y returns values from line containing arg
  # @return [String] value for line staring with `# <something> `
  # @param [Stirng] what = configuration name. E.g. 
  #
  #   # SLACK 1234567890987654321
  #
  # will return 1234567890987654321 when param what is SLACK
  #
  def self.matched_line what
    line = self.content.select do |line|
      line.start_with? "# #{what} "
    end.first
    line.split("# #{what.upcase} ").last if line
  end

  def self.content
    @@content ||= IO.read(@@alert_file + ".rb").split("\n")
  end

  # Alert methods
  
  # use to set status to ok
  # @param [String] message (optional) custom message to notify
  def ok! message = nil, data = nil
    NOCH.evaluate_for "ok", message, data
  end

  # use to set status to warning
  # @param [String] message (optional) custom message to notify
  def warning! message = nil, data = nil
    NOCH.evaluate_for "warning", message, data
  end

  # use to set status to critical
  # @param [String] message (optional) custom message to notify
  def critical! message = nil, data = nil
    NOCH.evaluate_for "critical", message, data
  end

  def skip! message = nil, data = nil
    NOCH.evaluate_for "skip", message, data
  end

  # use to get the current status. Useful when you save aditional data into status
  def get_current
    JSON.parse(NOCH.get_status)
  end

  def inspect
    {
      "version" => VERSION,
      "alert_name" => @@alert_name
    }
  end

end
