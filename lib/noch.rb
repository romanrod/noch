require "NOCH/version"
require 'slack-ruby-client'
require 'redis'

module NOCH
  
  class Error < StandardError; end

  # Sets default status. Used the first time execution with passed status
  # @param [String] to: the status to be saved
  # @return [Hash]
  def self.default to, data = nil
    {
      "status" => to,
      "data" => data
    }
  end
  
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

  # Returns the name of the alert
  def self.alert_name
    @@alert_name
  end

  # Returns the current status if the passed status is differente. If there is no current status save passed status with default data
  # @param [String] to: the status to be evaluated
  # @return [String] status: if passed value is different
  # @return [Hash] Data: data to be saved
  def self.changed to, data
    if (current = self.get_status)
      current_status = ::JSON.parse(current)['status']
      return current_status if current_status != to
      to
    else
      NOCH.create_object(to, data)
    end
  end

  # Returns the current status of the alert
  # @return [Hash] {"status"=>"ok", "last_change"=>"2019-07-17T22:51:03.081-03:00", "message"=>nil, "data"=>nil}
  def self.get_status
    @@redis.get(@@alert_name)
  end

  # Sends notification if status change. If not returns nil
  # @param [String] what: current status
  # @param [String] message (optional): the message to be sent on notification
  # @param [Hash] data (optional): Data to be saved for possible future evaluation
  # @return [Boolean] true if notification is sent, false if nothing changed
  def self.evaluate_for what, message = nil, data = nil
    raise "Unknown status #{what}. Allowed: ['ok','warning','critical','skip']" unless ['ok','warning','critical','skip'].include? what
    from = self.changed(what, data)
    !!(if (from != what)
        self.set what, message, data
        self.notify(from, what, message, data) unless what == 'skip'
    end)
  end

  # Saves into Redis the alert with `to` as initial status
  # @param [String] to: the value of the status to be saved
  # @param [Hash] data: the data to be saved
  def self.create_object(to, data)
    return to if @@redis.set(@@alert_name, self.default(to, data).to_json) == "OK"
    raise StandardError.new("Status `#{to}` could not be saved")
  end

  # Saves status, message and data into Redis
  # @param [String] to: status to save. It could be ['ok','warning','skip','critical']
  # @param [String] message (optional): The message to be sent on notification
  # @param [Hash] data(optional): data to be saved for future evaluation if needed
  def self.set to, message = nil, data = nil
    data = {
      'status' => to,
      'last_change' => Time.now,
      'message' => message,
      'data' => data
    }
    @@redis.set @@alert_name, data.to_json
  end

  # Prints out notification information and sends it
  # @param [String] from: the previous status
  # @param [Strig] to: the current status
  # @param [Hash] data (optional): the data to be saved
  # @return [Boolean] true if notification sent. false if not
  def self.notify from, to, message, data = nil
    string = "Alert: `#{@@alert_name} changed from `#{from}` to `#{to}` * #{message} *"
    string += "
    
    Data: 
    #{data}
    " if data
    print string
    self.send_slack(string, self.slack)
  end

  # Sends message notification through Slack to the given slack channel
  # @param [String] message: the message string to be sent
  # @param [String] slack_channel: the channel to send notification
  # @return [Boolean] true if notification sent. false if not
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
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def ok! opts = {}
    NOCH.evaluate_for "ok", opts[:message], opts[:data]
  end

  # use to set status to warning
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def warning! opts = {}
    NOCH.evaluate_for "warning", opts[:message], opts[:data]
  end

  # use to set status to critical
  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def critical! opts = {}
    NOCH.evaluate_for "critical", opts[:message], opts[:data]
  end

  # @param [Hash] opts 
  #
  # :message
  # :data
  #
  def skip! opts = {}
    NOCH.evaluate_for "skip", opts[:message], opts[:data]
  end

  # Returns the current status. Useful when you save aditional data into status
  # @return [Hash] {"status"=>"ok", "last_change"=>"2019-07-17T22:51:03.081-03:00", "message"=>nil, "data"=>nil}
  def get_current
    JSON.parse(NOCH.get_status)
  end

  # Returns the last data saved
  # @return [String] last data saved
  def last_data
    get_current['data']
  end

  def alert_name
    @@alert_name
  end

  def inspect
    {
      "version" => VERSION,
      "alert_name" => @@alert_name
    }
  end

end
